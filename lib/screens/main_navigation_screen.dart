import 'package:flutter/material.dart';

import 'catalog_screen.dart';
import 'home_screen.dart';
import 'notification_screen.dart';
import 'profile_screen.dart';
import '../services/app_session.dart';
import '../services/notification_center.dart';
import 'visit_schedule_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appSession,
      builder: (context, _) {
        final screens = appSession.isAuthenticated
            ? const [
                HomeScreen(),
                CatalogScreen(),
                VisitScheduleScreen(),
                NotificationScreen(),
                ProfileScreen(),
              ]
            : const [HomeScreen(), CatalogScreen(), ProfileScreen()];
        final items = appSession.isAuthenticated
            ? const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_rounded),
                  label: 'Accueil',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.search_rounded),
                  label: 'Biens',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_month_rounded),
                  label: 'Visites',
                ),
                BottomNavigationBarItem(
                  icon: _NotificationNavIcon(),
                  label: 'Alertes',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_rounded),
                  label: 'Profil',
                ),
              ]
            : const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_rounded),
                  label: 'Accueil',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.search_rounded),
                  label: 'Biens',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.login_rounded),
                  label: 'Connexion',
                ),
              ];

        if (_currentIndex >= screens.length) {
          _currentIndex = 0;
        }

        return Scaffold(
          body: IndexedStack(index: _currentIndex, children: screens),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            items: items,
          ),
        );
      },
    );
  }
}

class _NotificationNavIcon extends StatelessWidget {
  const _NotificationNavIcon();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: notificationCenter,
      builder: (context, _) {
        final count = notificationCenter.unreadCount;
        return Badge(
          isLabelVisible: count > 0,
          label: Text('$count'),
          child: const Icon(Icons.notifications_rounded),
        );
      },
    );
  }
}
