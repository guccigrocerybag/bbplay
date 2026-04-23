import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/auth_screen.dart';
import 'providers/user_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/settings_provider.dart';
import 'core/services/notification_service.dart';

// Цветовая палитра для приложения - улучшенная версия на основе лучших практик
class AppColors {
  // Основные цвета (темная тема) - вдохновлено Discord, Spotify, Twitch
  static const Color darkPrimary = Color(0xFF00FF00); // Кислотно-зеленый (оставляем ваш брендовый)
  static const Color darkSecondary = Color(0xFF9146FF); // Фиолетовый Twitch (яркий, насыщенный)
  static const Color darkBackground = Color(0xFF0F0F0F); // Почти черный (как у Spotify)
  static const Color darkSurface = Color(0xFF1A1A1A); // Темно-серый для карточек
  static const Color darkSurfaceVariant = Color(0xFF2A2A2A); // Вариант поверхности
  static const Color darkOnSurface = Color(0xFFE9ECEF); // Светло-серый текст (не чистый белый)
  static const Color darkOnSurfaceVariant = Color(0xFFB0B7C3); // Более светлый текст для второстепенного
  static const Color darkOnPrimary = Colors.black; // Черный текст на зеленом
  static const Color darkOnSecondary = Colors.white; // Белый текст на фиолетовом
  static const Color darkOutline = Color(0xFF404040); // Контур для темной темы
  
  // Основные цвета (светлая тема) - вдохновлено Telegram, Figma, современных приложений
  static const Color lightPrimary = Color(0xFF00C853); // Более мягкий зеленый (Material Design success)
  static const Color lightSecondary = Color(0xFF6200EE); // Фиолетовый Material Design
  static const Color lightBackground = Color(0xFFF8F9FA); // Очень светлый серый (как у Telegram)
  static const Color lightSurface = Colors.white; // Белый
  static const Color lightSurfaceVariant = Color(0xFFF1F3F5); // Светло-серый вариант
  static const Color lightOnSurface = Color(0xFF212529); // Темно-серый текст (не чистый черный)
  static const Color lightOnSurfaceVariant = Color(0xFF495057); // Более темный текст для второстепенного
  static const Color lightOnPrimary = Colors.white; // Белый текст на зеленом
  static const Color lightOnSecondary = Colors.white; // Белый текст на фиолетовом
  static const Color lightOutline = Color(0xFFDEE2E6); // Контур для светлой темы
  
  // Общие цвета - Material Design 3
  static const Color error = Color(0xFFBA1A1A); // Красный ошибки
  static const Color onError = Colors.white; // Текст на ошибке
  static const Color success = Color(0xFF00C853); // Зеленый успеха
  static const Color warning = Color(0xFFFFC107); // Желтый предупреждения
  static const Color info = Color(0xFF2196F3); // Синий информации
  
  // Дополнительные цвета
  static const Color dividerLight = Color(0xFFE0E0E0); // Разделитель для светлой темы
  static const Color dividerDark = Color(0xFF424242); // Разделитель для темной темы
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Инициализация сервиса уведомлений
  await NotificationService().init();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return MaterialApp(
          title: 'BBplay',
          debugShowCheckedModeBanner: false,
          themeMode: settings.flutterThemeMode,
          
          darkTheme: _buildDarkTheme(),
          theme: _buildLightTheme(),
          
          home: const AuthScreen(),
        );
      },
    );
  }

  // Создание темной темы
  static ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: AppColors.darkPrimary,
        secondary: AppColors.darkSecondary,
        surface: AppColors.darkSurface,
        surfaceVariant: AppColors.darkSurfaceVariant,
        background: AppColors.darkBackground,
        onSurface: AppColors.darkOnSurface,
        onSurfaceVariant: AppColors.darkOnSurfaceVariant,
        onPrimary: AppColors.darkOnPrimary,
        onSecondary: AppColors.darkOnSecondary,
        onError: AppColors.onError,
        error: AppColors.error,
        outline: AppColors.darkOutline,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkOnSurface,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkPrimary,
          foregroundColor: AppColors.darkOnPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.darkSecondary,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkOnSurface,
          side: BorderSide(color: AppColors.darkOutline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textTheme: GoogleFonts.montserratTextTheme(
        ThemeData.dark().textTheme.copyWith(
              bodyLarge: TextStyle(color: AppColors.darkOnSurface),
              bodyMedium: TextStyle(color: AppColors.darkOnSurface),
              bodySmall: TextStyle(color: AppColors.darkOnSurfaceVariant),
              titleLarge: TextStyle(color: AppColors.darkOnSurface),
              titleMedium: TextStyle(color: AppColors.darkOnSurface),
              titleSmall: TextStyle(color: AppColors.darkOnSurfaceVariant),
            ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: TextStyle(color: AppColors.darkOnSurfaceVariant),
        hintStyle: TextStyle(color: AppColors.darkOnSurfaceVariant.withOpacity(0.7)),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.darkOutline,
        thickness: 1,
        space: 1,
      ),
    );
  }

  // Создание светлой темы
  static ThemeData _buildLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: AppColors.lightPrimary,
        secondary: AppColors.lightSecondary,
        surface: AppColors.lightSurface,
        surfaceVariant: AppColors.lightSurfaceVariant,
        background: AppColors.lightBackground,
        onSurface: AppColors.lightOnSurface,
        onSurfaceVariant: AppColors.lightOnSurfaceVariant,
        onPrimary: AppColors.lightOnPrimary,
        onSecondary: AppColors.lightOnSecondary,
        onError: AppColors.onError,
        error: AppColors.error,
        outline: AppColors.lightOutline,
      ),
      scaffoldBackgroundColor: AppColors.lightBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightSurface,
        foregroundColor: AppColors.lightOnSurface,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lightPrimary,
          foregroundColor: AppColors.lightOnPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.lightSecondary,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.lightOnSurface,
          side: BorderSide(color: AppColors.lightOutline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textTheme: GoogleFonts.montserratTextTheme(
        ThemeData.light().textTheme.copyWith(
              bodyLarge: TextStyle(color: AppColors.lightOnSurface),
              bodyMedium: TextStyle(color: AppColors.lightOnSurface),
              bodySmall: TextStyle(color: AppColors.lightOnSurfaceVariant),
              titleLarge: TextStyle(color: AppColors.lightOnSurface),
              titleMedium: TextStyle(color: AppColors.lightOnSurface),
              titleSmall: TextStyle(color: AppColors.lightOnSurfaceVariant),
            ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: TextStyle(color: AppColors.lightOnSurfaceVariant),
        hintStyle: TextStyle(color: AppColors.lightOnSurfaceVariant.withOpacity(0.7)),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.lightOutline,
        thickness: 1,
        space: 1,
      ),
    );
  }
}