import 'package:flutter/foundation.dart';

import '../models/app_notification.dart';

class NotificationCenter extends ChangeNotifier {
  final List<AppNotification> _items = [];

  List<AppNotification> get items => List.unmodifiable(_items);

  int get unreadCount => _items.where((item) => !item.isRead).length;

  void push({
    required String title,
    required String message,
    required AppNotificationType type,
  }) {
    _items.insert(
      0,
      AppNotification(
        id: 'notif_${DateTime.now().microsecondsSinceEpoch}',
        title: title,
        message: message,
        type: type,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void markAllRead() {
    for (var i = 0; i < _items.length; i++) {
      _items[i] = _items[i].copyWith(isRead: true);
    }
    notifyListeners();
  }
}

final notificationCenter = NotificationCenter();
