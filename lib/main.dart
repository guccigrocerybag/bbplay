import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/splash_screen.dart';
import 'providers/user_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/settings_provider.dart';
import 'core/services/notification_service.dart';
import 'core/services/cache_service.dart';

// ============================================================
// ЦВЕТОВАЯ ПАЛИТРА BBplay — ВДОХНОВЛЕНО SPOTIFY
// ============================================================
// Spotify использует:
// - Тёплый чёрный фон (#121212) вместо чистого #000
// - Один акцентный цвет — травянисто-зелёный (#1DB954)
// - Иерархию текста через прозрачность белого
// - Минимум цветов, максимум воздуха
// ============================================================
class AppColors {
  // ─── ТЁМНАЯ ТЕМА (Spotify Premium Dark) ───────────────────
  static const Color darkPrimary = Color(0xFF1DB954); // Spotify Green
  static const Color darkPrimaryHover = Color(0xFF1ED760); // Spotify Green hover
  static const Color darkBackground = Color(0xFF121212); // Тёплый чёрный (Spotify)
  static const Color darkSurface = Color(0xFF1A1A1A); // Карточки
  static const Color darkSurfaceHover = Color(0xFF282828); // Ховер карточки
  static const Color darkSurfaceActive = Color(0xFF333333); // Активный элемент
  static const Color darkOnSurface = Color(0xFFFFFFFF); // Белый текст (100%)
  static const Color darkOnSurfaceSecondary = Color(0xFFB3B3B3); // Серый текст (70%)
  static const Color darkOnSurfaceTertiary = Color(0xFF727272); // Бледный текст (45%)
  static const Color darkOnPrimary = Colors.black; // Чёрный текст на зелёном
  static const Color darkOutline = Color(0xFF292929); // Едва заметный разделитель
  
  // ─── СВЕТЛАЯ ТЕМА (Spotify Light — минимализм) ───────────
  static const Color lightPrimary = Color(0xFF1DB954); // Тот же Spotify Green
  static const Color lightPrimaryHover = Color(0xFF1ED760);
  static const Color lightBackground = Color(0xFFFFFFFF); // Белый фон
  static const Color lightSurface = Color(0xFFF5F5F5); // Светло-серые карточки
  static const Color lightSurfaceHover = Color(0xFFE8E8E8);
  static const Color lightOnSurface = Color(0xFF121212); // Почти чёрный текст
  static const Color lightOnSurfaceSecondary = Color(0xFF535353); // Серый текст
  static const Color lightOnSurfaceTertiary = Color(0xFF8C8C8C); // Бледный текст
  static const Color lightOnPrimary = Colors.white; // Белый текст на зелёном
  static const Color lightOutline = Color(0xFFD9D9D9); // Разделитель
  
  // ─── ОБЩИЕ ЦВЕТА ──────────────────────────────────────────
  static const Color error = Color(0xFFE22134); // Красный Spotify
  static const Color onError = Colors.white;
  static const Color success = Color(0xFF1DB954); // Тот же зелёный
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF2196F3);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Инициализация сервиса уведомлений
  await NotificationService().init();
  
  // Инициализация Hive для оффлайн-кеша
  await CacheService.init();
  
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
          
          home: const SplashScreen(),
        );
      },
    );
  }

  // Создание темной темы (Spotify Premium Dark)
  static ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: AppColors.darkPrimary,
        secondary: AppColors.darkPrimary, // Используем тот же зелёный
        surface: AppColors.darkSurface,
        surfaceContainerHighest: AppColors.darkSurfaceHover,
        onSurface: AppColors.darkOnSurface,
        onSurfaceVariant: AppColors.darkOnSurfaceSecondary,
        onPrimary: AppColors.darkOnPrimary,
        onSecondary: AppColors.darkOnPrimary,
        onError: AppColors.onError,
        error: AppColors.error,
        outline: AppColors.darkOutline,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.darkOnSurface,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkPrimary,
          foregroundColor: AppColors.darkOnPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24), // Spotify-style pill
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 0.5,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.darkOnSurface,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkOnSurface,
          side: BorderSide(color: AppColors.darkOnSurfaceSecondary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
      textTheme: GoogleFonts.montserratTextTheme(
        ThemeData.dark().textTheme.copyWith(
              displayLarge: TextStyle(
                color: AppColors.darkOnSurface,
                fontWeight: FontWeight.bold,
              ),
              displayMedium: TextStyle(
                color: AppColors.darkOnSurface,
                fontWeight: FontWeight.bold,
              ),
              headlineLarge: TextStyle(
                color: AppColors.darkOnSurface,
                fontWeight: FontWeight.bold,
              ),
              headlineMedium: TextStyle(
                color: AppColors.darkOnSurface,
                fontWeight: FontWeight.w600,
              ),
              titleLarge: TextStyle(color: AppColors.darkOnSurface),
              titleMedium: TextStyle(color: AppColors.darkOnSurface),
              titleSmall: TextStyle(color: AppColors.darkOnSurfaceSecondary),
              bodyLarge: TextStyle(color: AppColors.darkOnSurface),
              bodyMedium: TextStyle(color: AppColors.darkOnSurfaceSecondary),
              bodySmall: TextStyle(color: AppColors.darkOnSurfaceTertiary),
              labelLarge: TextStyle(
                color: AppColors.darkOnSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceHover,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: TextStyle(color: AppColors.darkOnSurfaceSecondary),
        hintStyle: TextStyle(color: AppColors.darkOnSurfaceTertiary),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.darkOutline,
        thickness: 1,
        space: 1,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkBackground,
        selectedItemColor: AppColors.darkOnSurface,
        unselectedItemColor: AppColors.darkOnSurfaceSecondary,
      ),
    );
  }

  // Создание светлой темы (Spotify Light)
  static ThemeData _buildLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: AppColors.lightPrimary,
        secondary: AppColors.lightPrimary,
        surface: AppColors.lightSurface,
        surfaceContainerHighest: AppColors.lightSurfaceHover,
        onSurface: AppColors.lightOnSurface,
        onSurfaceVariant: AppColors.lightOnSurfaceSecondary,
        onPrimary: AppColors.lightOnPrimary,
        onSecondary: AppColors.lightOnPrimary,
        onError: AppColors.onError,
        error: AppColors.error,
        outline: AppColors.lightOutline,
      ),
      scaffoldBackgroundColor: AppColors.lightBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        foregroundColor: AppColors.lightOnSurface,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lightPrimary,
          foregroundColor: AppColors.lightOnPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 0.5,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.lightOnSurface,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.lightOnSurface,
          side: BorderSide(color: AppColors.lightOnSurfaceSecondary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
      textTheme: GoogleFonts.montserratTextTheme(
        ThemeData.light().textTheme.copyWith(
              displayLarge: TextStyle(
                color: AppColors.lightOnSurface,
                fontWeight: FontWeight.bold,
              ),
              displayMedium: TextStyle(
                color: AppColors.lightOnSurface,
                fontWeight: FontWeight.bold,
              ),
              headlineLarge: TextStyle(
                color: AppColors.lightOnSurface,
                fontWeight: FontWeight.bold,
              ),
              headlineMedium: TextStyle(
                color: AppColors.lightOnSurface,
                fontWeight: FontWeight.w600,
              ),
              titleLarge: TextStyle(color: AppColors.lightOnSurface),
              titleMedium: TextStyle(color: AppColors.lightOnSurface),
              titleSmall: TextStyle(color: AppColors.lightOnSurfaceSecondary),
              bodyLarge: TextStyle(color: AppColors.lightOnSurface),
              bodyMedium: TextStyle(color: AppColors.lightOnSurfaceSecondary),
              bodySmall: TextStyle(color: AppColors.lightOnSurfaceTertiary),
              labelLarge: TextStyle(
                color: AppColors.lightOnSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurfaceHover,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: TextStyle(color: AppColors.lightOnSurfaceSecondary),
        hintStyle: TextStyle(color: AppColors.lightOnSurfaceTertiary),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.lightOutline,
        thickness: 1,
        space: 1,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightBackground,
        selectedItemColor: AppColors.lightOnSurface,
        unselectedItemColor: AppColors.lightOnSurfaceSecondary,
      ),
    );
  }
}