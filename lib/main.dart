import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/prestige_splash_screen.dart';
import 'services/app_session.dart';
import 'services/push_notification_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  await appSession.restore();
  runApp(const ImmoAgenceApp());
  unawaited(pushNotificationService.initialize());
}

class ImmoAgenceApp extends StatelessWidget {
  const ImmoAgenceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ImmoAgence Senegal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const PrestigeSplashScreen(),
    );
  }
}
