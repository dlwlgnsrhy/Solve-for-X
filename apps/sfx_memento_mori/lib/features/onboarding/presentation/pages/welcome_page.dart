import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sfx_memento_mori/core/theme/neon_colors.dart';
import 'package:sfx_memento_mori/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:sfx_memento_mori/features/onboarding/presentation/providers/onboarding_provider.dart';

/// Welcome landing screen shown before the onboarding form.
/// Displays a powerful visual with animated mini grid preview.
class WelcomePage extends ConsumerStatefulWidget {
  const WelcomePage({super.key});

  @override
  ConsumerState<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends ConsumerState<WelcomePage>
    with TickerProviderStateMixin {
  late AnimationController _gridController;
  late Animation<double> _gridOpacity;
  late AnimationController _titleGlowController;
  late Animation<double> _titleGlowAnimation;
  late AnimationController _particleController;
  late AnimationController _counterController;

  // Animated counter target
  int _countedValue = 0;
  final int _targetValue = 4160;

  // Random positions for floating particles
  final List<_Particle> _particles = [];
  final math.Random _random = math.Random(42);

  @override
  void initState() {
    super.initState();

    // Grid fade-in controller
    _gridController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _gridOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _gridController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeInOut),
      ),
    );
    _gridController.forward();

    // Title pulsing neon glow
    _titleGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _titleGlowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _titleGlowController, curve: Curves.easeInOut),
    );

    // Floating particles
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // Generate random particles
    for (int i = 0; i < 30; i++) {
      _particles.add(_Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: 1.0 + _random.nextDouble() * 3.0,
        speed: 0.2 + _random.nextDouble() * 0.8,
        opacity: 0.1 + _random.nextDouble() * 0.3,
        delay: _random.nextDouble() * 2.0,
      ));
    }

    // Animated counter (counts up from 0 to 4160)
    _counterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _counterController.addStatusListener((status) {
      if (status == AnimationStatus.forward) {
        _startCounting();
      }
    });
  }

  void _startCounting() {
    final duration = _counterController.duration!.inMilliseconds;
    final startTime = DateTime.now();

    void tick() {
      if (!mounted) return;
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      final progress = (elapsed / duration).clamp(0.0, 1.0);
      // Ease out cubic for natural feel
      final easedProgress = 1 - math.pow(1 - progress, 3);
      setState(() {
        _countedValue = (_targetValue * easedProgress).round();
      });
      if (progress < 1.0) {
        Future.delayed(const Duration(milliseconds: 16), tick);
      }
    }
    tick();
  }

  @override
  void dispose() {
    _gridController.dispose();
    _titleGlowController.dispose();
    _particleController.dispose();
    _counterController.dispose();
    super.dispose();
  }

  void _proceedToOnboarding() async {
    final prefs = ref.read(preferenceServiceProvider);
    await prefs.setWelcomeSeen(true);
    if (mounted) {
      // Trigger counter immediately if it hasn't started yet
      if (!_counterController.isAnimating) {
        _counterController.forward(from: 0.0);
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: NeonColors.background,
      body: Stack(
        children: [
          // Floating particle background
          _buildParticles(screenSize),

          // Top green glow
          Positioned(
            top: -100,
            left: screenSize.width / 2 - 150,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    NeonColors.glowGreen,
                    Colors.transparent,
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 1500.ms),
          ),

          // Bottom cyan glow
          Positioned(
            bottom: -80,
            right: screenSize.width / 2 - 100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    NeonColors.glowCyan,
                    Colors.transparent,
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 1500.ms, delay: 300.ms),
          ),

          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Spacer(flex: 1),

                  // Title with pulsing neon glow
                  AnimatedBuilder(
                    animation: _titleGlowAnimation,
                    builder: (context, child) {
                      return Text(
                        'MEMENTO MORI',
                        style: TextStyle(
                          color: NeonColors.neonGreen,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 8,
                          shadows: [
                            Shadow(
                              color: NeonColors.glowGreen.withValues(
                                alpha: 0.6 * _titleGlowAnimation.value,
                              ),
                              blurRadius: 20 * _titleGlowAnimation.value,
                              offset: const Offset(0, 0),
                            ),
                            Shadow(
                              color: NeonColors.neonGreen.withValues(
                                alpha: 0.3 * _titleGlowAnimation.value,
                              ),
                              blurRadius: 40 * _titleGlowAnimation.value,
                              offset: const Offset(0, 0),
                            ),
                          ],
                        ),
                      );
                    },
                  ).animate()
                      .fadeIn(duration: 800.ms)
                      .slideY(begin: -0.5, end: 0, duration: 800.ms),
                  const SizedBox(height: 8),
                  Text(
                    '일상적 죽음의 기억',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                      letterSpacing: 3,
                    ),
                  ).animate().fadeIn(duration: 800.ms, delay: 200.ms),
                  const Spacer(flex: 1),

                  // Big number display with animated counter
                  Column(
                    children: [
                      Text(
                        '80년',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 44,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ).animate().fadeIn(duration: 600.ms, delay: 400.ms),
                      Text(
                        '=',
                        style: TextStyle(
                          color: NeonColors.neonCyan,
                          fontSize: 32,
                          fontWeight: FontWeight.w300,
                        ),
                      ).animate().fadeIn(duration: 600.ms, delay: 500.ms),
                      Text(
                        '$_countedValue주',
                        style: TextStyle(
                          color: NeonColors.neonGreen,
                          fontSize: 60,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1,
                          shadows: [
                            Shadow(
                              color: NeonColors.glowGreen,
                              blurRadius: 30,
                            ),
                          ],
                        ),
                      ).animate(
                        onPlay: (ctrl) {
                          ctrl.repeat(period: 3.seconds);
                          // Start counter when this animation begins
                          Future.delayed(const Duration(milliseconds: 500), () {
                            if (mounted) _counterController.forward(from: 0.0);
                          });
                        },
                      ).fadeIn(duration: 800.ms, delay: 600.ms).scale(
                        begin: const Offset(0.95, 0.95),
                        end: const Offset(1, 1),
                        duration: 1.5.seconds,
                      ),
                    ],
                  ),

                  const Spacer(flex: 2),

                  // Larger animated mini grid preview
                  AnimatedBuilder(
                    animation: _gridOpacity,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _gridOpacity.value,
                        child: _buildMiniGrid(screenSize.width),
                      );
                    },
                  ),

                  const Spacer(flex: 1),

                  // Motivational text
                  Text(
                    '당신의 남은 시간을\n시각화합니다',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 800.ms, delay: 800.ms)
                      .slideY(begin: 0.5, end: 0, duration: 800.ms),

                  const SizedBox(height: 8),
                  Text(
                    '매 순간이 소중함을 기억하세요',
                    style: TextStyle(
                      color: NeonColors.neonCyan.withValues(alpha: 0.6),
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ).animate().fadeIn(duration: 600.ms, delay: 1000.ms),

                  const Spacer(flex: 1),

                  // Gradient start button
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [
                            NeonColors.neonGreen,
                            NeonColors.neonCyan,
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: NeonColors.glowGreen,
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _proceedToOnboarding,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          '시작하기',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 3,
                            color: NeonColors.background,
                          ),
                        ),
                      ),
                    ),
                  ).animate()
                      .fadeIn(duration: 600.ms, delay: 1200.ms)
                      .slideY(begin: 0.5, end: 0, duration: 600.ms),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Floating particles background effect
  Widget _buildParticles(Size screenSize) {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        final t = _particleController.value;
        return Stack(
          children: _particles.map((particle) {
            final particleT = ((t + particle.delay) % 1.0);
            return Positioned(
              left: particle.x * screenSize.width,
              top: (1.0 - particleT) * screenSize.height * particle.speed,
              child: Container(
                width: particle.size,
                height: particle.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: NeonColors.neonGreen.withValues(alpha: particle.opacity * (1.0 - particleT)),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildMiniGrid(double screenWidth) {
    // Show a larger 20-column grid representing ~80 years
    const cols = 20;
    const totalCells = 416; // 80 years * 52 weeks, capped for display
    const filledCells = 125; // ~24 years worth

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: NeonColors.neonGreen.withValues(alpha: 0.15),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color: NeonColors.surface.withValues(alpha: 0.5),
        boxShadow: [
          BoxShadow(
            color: NeonColors.glowGreen.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: totalCells,
        itemBuilder: (context, index) {
          final isFilled = index < filledCells;
          final isCurrent = index == filledCells;
          return Container(
            decoration: BoxDecoration(
              color: isCurrent
                  ? NeonColors.todayPulse
                  : isFilled
                      ? NeonColors.pastWeek
                      : NeonColors.neonGreen.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
              boxShadow: isCurrent
                  ? [
                      BoxShadow(
                        color: NeonColors.todayPulse.withValues(alpha: 0.5),
                        blurRadius: 6,
                      ),
                    ]
                  : null,
            ),
          );
        },
      ),
    );
  }
}

class _Particle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double opacity;
  final double delay;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.delay,
  });
}
