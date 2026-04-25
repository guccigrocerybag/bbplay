import 'dart:async';
import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../providers/booking_provider.dart';
import '../providers/settings_provider.dart';
import 'news_screen.dart';
import 'clubs_screen.dart';
import 'booking_screen.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';
import 'tournaments_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();
  final PageController _pageController = PageController();
  bool _isOffline = false;
  StreamSubscription? _connectivitySubscription;

  // Список экранов приложения
  final List<Widget> _screens = [
    const NewsScreen(),
    const ClubsScreen(),
    const BookingScreen(),
    const TournamentsScreen(),
    const ChatScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final isOffline = results.contains(ConnectivityResult.none);
      if (mounted && _isOffline != isOffline) {
        setState(() => _isOffline = isOffline);
      }
    });
  }

  Future<void> _checkConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    if (mounted) {
      setState(() => _isOffline = results.contains(ConnectivityResult.none));
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Получаем провайдеры
    final bookingProv = Provider.of<BookingProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    
    // Определяем цвета в зависимости от темы
    final colorScheme = Theme.of(context).colorScheme;
    final Color navBarColor = colorScheme.surface;
    final Color bgColor = Theme.of(context).scaffoldBackgroundColor;
    final Color iconColor = colorScheme.onSurface;
    final Color buttonColor = colorScheme.primary;

    // Слушатель для программного переключения вкладок (например, из списка клубов)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        int targetPage = bookingProv.currentTabIndex;
        if (_pageController.page?.round() != targetPage) {
          _bottomNavigationKey.currentState?.setPage(targetPage);
          _pageController.jumpToPage(targetPage);
        }
      }
    });

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // Индикатор оффлайн-режима
          if (_isOffline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              color: Colors.orange.shade800,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off, size: 16, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    settings.getText('offline_mode'),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: _screens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: CurvedNavigationBar(
        key: _bottomNavigationKey,
        index: bookingProv.currentTabIndex,
        height: 60.0,
        items: <Widget>[
          Icon(FontAwesomeIcons.newspaper, size: 22, color: iconColor),
          Icon(FontAwesomeIcons.mapLocationDot, size: 22, color: iconColor),
          Icon(FontAwesomeIcons.desktop, size: 22, color: iconColor),
          Icon(FontAwesomeIcons.trophy, size: 22, color: iconColor),
          Icon(FontAwesomeIcons.robot, size: 22, color: iconColor),
          Icon(FontAwesomeIcons.solidUser, size: 22, color: iconColor),
        ],
        color: navBarColor,
        buttonBackgroundColor: buttonColor,
        backgroundColor: bgColor,
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 300),
        onTap: (index) {
          bookingProv.setTab(index);
          _pageController.jumpToPage(index);
        },
      ),
    );
  }
}
