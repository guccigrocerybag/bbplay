import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/settings_provider.dart';
import '../widgets/app_animations.dart';
import 'auth_screen.dart';
import 'onboarding_screen.dart';

/// Анимированный экран загрузки при запуске приложения.
///
/// Показывает логотип BBplay с медведем с эффектом появления и свечения.
/// После завершения анимации проверяет, был ли показан онбординг,
/// и перенаправляет на соответствующий экран.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Автоматический переход через 3.5 секунды
    Future.delayed(const Duration(milliseconds: 3500), _navigateToNext);
  }

  Future<void> _navigateToNext() async {
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final onboardingShown = prefs.getBool('onboarding_shown') ?? false;

    if (!mounted) return;

    if (onboardingShown) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF8F9FA),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Анимация логотипа с медведем
            const BearLogoAnimation(
              size: 180,
            ),
            const SizedBox(height: 32),
            Text(
              'BBPLAY',
              style: TextStyle(
                color: colorScheme.primary,
                fontSize: 48,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              settings.getText('splash_loading').toUpperCase(),
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.6),
                fontSize: 14,
                letterSpacing: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
