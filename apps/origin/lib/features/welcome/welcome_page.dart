import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:origin/core/theme/app_theme.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColor.bgPrimary,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),

                      // Logo / Icon
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColor.neonGreen, width: 2),
                        ),
                        child: const Icon(
                          Icons.fingerprint,
                          size: 44,
                          color: AppColor.neonGreen,
                        ),
                      ).animate().scale(
                        duration: 600.ms,
                        delay: 100.ms,
                        curve: Curves.easeOutBack,
                      ),

                      const SizedBox(height: 40),

                      // Title
                      Text(
                        'Origin',
                        style: style.textTheme.displayLarge!.copyWith(
                          color: AppColor.textPrimary,
                          letterSpacing: -1.5,
                        ),
                      ).animate().fadeIn(duration: 500.ms, delay: 300.ms),

                      const SizedBox(height: 12),

                      // Tagline
                      Text(
                        'Your mind. Your rhythm. Proven original.',
                        textAlign: TextAlign.center,
                        style: style.textTheme.titleMedium!.copyWith(
                          color: AppColor.textSecondary,
                          fontWeight: FontWeight.w400,
                        ),
                      ).animate().fadeIn(duration: 500.ms, delay: 500.ms),

                      const SizedBox(height: 56),

                      // Features
                      ..._buildFeatureItems(style).animate().fadeIn(duration: 400.ms, delay: 700.ms),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  List<Widget> _buildFeatureItems(ThemeData style) {
    return [
      _FeatureItem(
        iconIcon: const Icon(Icons.favorite_rounded, size: 20, color: AppColor.neonGreen),
        title: 'Human Pulse Tracker',
        description: 'Records the rhythm of your thoughts, keystroke by keystroke.',
      ),
      _FeatureItem(
        iconIcon: InsightsIcon(),
        title: 'Authentic Analyzer',
        description: 'Calculates your unique intellectual fingerprint from writing patterns.',
      ),
      _FeatureItem(
        iconIcon: const Icon(Icons.verified_rounded, size: 20, color: AppColor.neonGreen),
        title: 'Origin Stamp',
        description: 'Prove your work with cryptographic, tamper-proof verification.',
      ),
    ]
        .asMap()
        .map(
          (index, item) => MapEntry(
            index,
            item.animate().fadeIn(duration: 400.ms, delay: (900 + index * 120).ms),
          ),
        )
        .values
        .toList();
  }

  Widget _buildBottomBar(BuildContext context) {
    final style = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 40),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).pushReplacementNamed('/keystroke-capture');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColor.neonGreen,
            foregroundColor: AppColor.bgPrimary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            textStyle: style.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          child: const Text('Begin Writing'),
        ).animate().fadeIn(duration: 500.ms, delay: 1400.ms),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final Widget iconIcon;
  final String title;
  final String description;

  const _FeatureItem({
    required this.iconIcon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColor.neonGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: iconIcon,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: style.textTheme.titleMedium!.copyWith(
                    color: AppColor.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: style.textTheme.bodyMedium!.copyWith(
                    color: AppColor.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom icon for the analytics feature.
class InsightsIcon extends StatelessWidget {
  const InsightsIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(20, 20),
      painter: _GridPainter(),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColor.neonGreen
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    const d = 6.0;

    path.moveTo(d, size.height - d);
    path.lineTo(d + 5, size.height - d - 8);
    path.lineTo(d + 12, size.height - d - 4);
    path.lineTo(d + 19, size.height - d - 9);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

