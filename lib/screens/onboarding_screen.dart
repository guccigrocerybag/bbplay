import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../providers/settings_provider.dart';
import 'auth_screen.dart';

/// Экран онбординга при первом запуске приложения.
///
/// Показывает 3 страницы с SVG-иконками в зелёном цвете BBplay.
/// После просмотра сохраняет флаг `onboarding_shown` в SharedPreferences.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPageData> _pages = [
    _OnboardingPageData(
      svgAsset: 'assets/images/onboarding_gamepad.svg',
      titleKey: 'onb_1_title',
      descriptionKey: 'onb_1_sub',
    ),
    _OnboardingPageData(
      svgAsset: 'assets/images/onboarding_monitor.svg',
      titleKey: 'onb_2_title',
      descriptionKey: 'onb_2_sub',
    ),
    _OnboardingPageData(
      svgAsset: 'assets/images/onboarding_trophy.svg',
      titleKey: 'onb_3_title',
      descriptionKey: 'onb_3_sub',
    ),
  ];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_shown', true);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Кнопка "Пропустить"
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _completeOnboarding,
                child: Text(
                  settings.getText('onb_skip'),
                  style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
              ),
            ),

            // PageView с контентом
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) =>
                    setState(() => _currentPage = page),
                children: _pages
                    .map((page) => _buildPage(page, colorScheme, settings))
                    .toList(),
              ),
            ),

            // Нижняя панель
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  // Индикатор страниц
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: _pages.length,
                    effect: ExpandingDotsEffect(
                      activeDotColor: colorScheme.primary,
                      dotColor: colorScheme.onSurface.withOpacity(0.2),
                      dotHeight: 8,
                      dotWidth: 8,
                      expansionFactor: 3,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Кнопка "Далее" / "Начать"
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage < _pages.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _completeOnboarding();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _currentPage < _pages.length - 1
                            ? settings.getText('onb_next')
                            : settings.getText('onb_start'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(
      _OnboardingPageData page, ColorScheme colorScheme, SettingsProvider settings) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // SVG-иконка
          SizedBox(
            width: 180,
            height: 180,
            child: SvgPicture.asset(
              page.svgAsset,
              width: 180,
              height: 180,
            ),
          ),
          const SizedBox(height: 48),

          // Заголовок
          Text(
            settings.getText(page.titleKey),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Описание
          Text(
            settings.getText(page.descriptionKey),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.7),
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Внутренняя модель данных для страницы онбординга
class _OnboardingPageData {
  final String svgAsset;
  final String titleKey;
  final String descriptionKey;

  const _OnboardingPageData({
    required this.svgAsset,
    required this.titleKey,
    required this.descriptionKey,
  });
}
