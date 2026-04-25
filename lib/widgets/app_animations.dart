import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

// ============================================================
// КАСТОМНЫЕ АНИМАЦИИ ДЛЯ BBplay
// ============================================================
// Содержит:
// 1. BearLogoAnimation — анимация логотипа с медведем (SplashScreen)
// 2. GamingSpinner — вращающийся геймерский спиннер (загрузка)
// 3. SuccessAnimation — анимация успеха с конфетти (бронирование)
// 4. LoadingDots — анимированные точки (микро-загрузки)
// ============================================================

/// Анимация логотипа BBplay с медведем для SplashScreen
/// Медведь появляется с эффектом свечения и пульсации
class BearLogoAnimation extends StatefulWidget {
  final double size;
  final VoidCallback? onAnimationComplete;

  const BearLogoAnimation({
    super.key,
    this.size = 200,
    this.onAnimationComplete,
  });

  @override
  State<BearLogoAnimation> createState() => _BearLogoAnimationState();
}

class _BearLogoAnimationState extends State<BearLogoAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // Появление (fade in + scale up)
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    // Свечение (пульсация после появления)
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.7, curve: Curves.easeInOut),
      ),
    );

    // Финальная пульсация
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAnimationComplete?.call();
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeInAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value * _pulseAnimation.value,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Эффект свечения
                Container(
                  width: widget.size * 1.5,
                  height: widget.size * 1.5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary
                            .withValues(alpha: _glowAnimation.value * 0.3),
                        blurRadius: 40 * _glowAnimation.value,
                        spreadRadius: 10 * _glowAnimation.value,
                      ),
                    ],
                  ),
                ),
                // Логотип (SVG)
                SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: SvgPicture.asset(
                    'assets/images/logo-round-1.svg',
                    fit: BoxFit.contain,
                    placeholderBuilder: (context) => const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Геймерский вращающийся спиннер для экранов загрузки
/// Анимированная иконка геймпада с вращением и пульсацией
class GamingSpinner extends StatefulWidget {
  final double size;
  final Color? color;

  const GamingSpinner({
    super.key,
    this.size = 60,
    this.color,
  });

  @override
  State<GamingSpinner> createState() => _GamingSpinnerState();
}

class _GamingSpinnerState extends State<GamingSpinner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _rotationAnimation = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.9 + (sin(_controller.value * pi) * 0.1),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Внешнее кольцо
              SizedBox(
                width: widget.size,
                height: widget.size,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              // Иконка геймпада
              Transform.rotate(
                angle: _rotationAnimation.value,
                child: Icon(
                  Icons.sports_esports,
                  size: widget.size * 0.5,
                  color: color,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Анимация успеха с конфетти и пульсирующей галочкой
/// Используется после успешного бронирования
class SuccessAnimation extends StatefulWidget {
  final double size;
  final String message;

  const SuccessAnimation({
    super.key,
    this.size = 150,
    this.message = 'Бронирование успешно!',
  });

  @override
  State<SuccessAnimation> createState() => _SuccessAnimationState();
}

class _SuccessAnimationState extends State<SuccessAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _checkScale;
  late Animation<double> _checkOpacity;
  late Animation<double> _confettiOpacity;

  final List<_ConfettiParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    // Генерируем частицы конфетти
    for (int i = 0; i < 30; i++) {
      _particles.add(_ConfettiParticle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: 4 + _random.nextDouble() * 8,
        color: Colors.primaries[_random.nextInt(Colors.primaries.length)],
        delay: _random.nextDouble() * 0.5,
        speed: 0.5 + _random.nextDouble() * 1.0,
      ));
    }

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward();

    _checkScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.7, curve: Curves.elasticOut),
      ),
    );

    _checkOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.5, curve: Curves.easeIn),
      ),
    );

    _confettiOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: widget.size,
              height: widget.size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Конфетти
                  if (_confettiOpacity.value > 0)
                    ..._particles.map((particle) {
                      final progress = (_controller.value - particle.delay)
                          .clamp(0.0, 1.0);
                      if (progress <= 0) return const SizedBox.shrink();

                      return Positioned(
                        left: particle.x * widget.size,
                        top: particle.y * widget.size -
                            progress * particle.speed * 50,
                        child: Opacity(
                          opacity: (1 - progress) * _confettiOpacity.value,
                          child: Container(
                            width: particle.size,
                            height: particle.size,
                            decoration: BoxDecoration(
                              color: particle.color,
                              borderRadius: BorderRadius.circular(
                                  _random.nextBool() ? 0 : particle.size / 2),
                            ),
                          ),
                        ),
                      );
                    }),
                  // Пульсирующая галочка
                  Transform.scale(
                    scale: _checkScale.value,
                    child: Opacity(
                      opacity: _checkOpacity.value,
                      child: Container(
                        width: widget.size * 0.5,
                        height: widget.size * 0.5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withValues(alpha: 0.4),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.message,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Внутренняя модель частицы конфетти
class _ConfettiParticle {
  final double x;
  final double y;
  final double size;
  final Color color;
  final double delay;
  final double speed;

  const _ConfettiParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    required this.delay,
    required this.speed,
  });
}

/// Анимированные точки для микро-загрузок
class LoadingDots extends StatefulWidget {
  final Color? color;
  final double dotSize;

  const LoadingDots({
    super.key,
    this.color,
    this.dotSize = 8,
  });

  @override
  State<LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<LoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.15;
            final value = ((_controller.value - delay) % 1.0);
            final scale = sin(value * pi) * 0.5 + 0.5;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Transform.scale(
                scale: 0.5 + scale * 0.5,
                child: Container(
                  width: widget.dotSize,
                  height: widget.dotSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.3 + scale * 0.7),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
