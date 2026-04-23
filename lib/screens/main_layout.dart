import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../main.dart'; // Для AppColors
import '../providers/booking_provider.dart';
import '../providers/settings_provider.dart';
import 'news_screen.dart';
import 'clubs_screen.dart';
import 'booking_screen.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();
  final PageController _pageController = PageController();

  // Список экранов приложения
  final List<Widget> _screens = [
    const NewsScreen(),
    const ClubsScreen(),
    const BookingScreen(),
    const ChatScreen(),
    const ProfileScreen(),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Получаем провайдеры
    final bookingProv = Provider.of<BookingProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    
    // Определяем цвета в зависимости от темы
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
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
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Отключаем свайп, только тапы
        children: _screens,
      ),
      bottomNavigationBar: CurvedNavigationBar(
        key: _bottomNavigationKey,
        index: bookingProv.currentTabIndex,
        height: 60.0,
        items: <Widget>[
          Icon(FontAwesomeIcons.newspaper, size: 22, color: iconColor),
          Icon(FontAwesomeIcons.mapLocationDot, size: 22, color: iconColor),
          Icon(FontAwesomeIcons.desktop, size: 22, color: iconColor),
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