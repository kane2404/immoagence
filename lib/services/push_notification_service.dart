import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../firebase_options.dart';
import '../models/app_notification.dart';
import 'api_config.dart';
import 'app_session.dart';
import 'notification_center.dart';

class PushNotificationService {
  const PushNotificationService();

  Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      final token = await messaging.getToken();
      if (token != null) {
        await syncToken(token);
      }
      FirebaseMessaging.onMessage.listen((message) {
        notificationCenter.push(
          title: message.notification?.title ?? 'Notification',
          message: message.notification?.body ?? 'Nouvelle activite recue.',
          type: AppNotificationType.system,
        );
      });
    } catch (error) {
      debugPrint('Firebase messaging indisponible: $error');
    }
  }

  Future<void> syncToken(String token) async {
    final sessionToken = appSession.token;
    if (sessionToken == null) return;

    try {
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $sessionToken',
        },
        body: jsonEncode({'token': token}),
      );
    } catch (error) {
      debugPrint('Synchronisation FCM impossible: $error');
    }
  }
}

const pushNotificationService = PushNotificationService();
