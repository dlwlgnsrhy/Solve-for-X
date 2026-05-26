import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:origin/core/theme/app_theme.dart';

/// Score gauge widget with animated arc.
class ScoreGauge extends StatelessWidget {
  final double score;
  final double size;

  const ScoreGauge({
    super.key,
    required this.score,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    final clampedScore = score.clamp(0.0, 100.0);
    final fraction = clampedScore / 100.0;
    final radius = size / 2;
    final strokeWidth = 10.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background track
          CustomPaint(
            size: Size(size, size),
            painter: _GaugeTrackPainter(
              radius: radius,
              strokeWidth: strokeWidth,
              scoreFraction: fraction,
            ),
          ).animate().scale(
                duration: 800.ms,
                curve: Curves.easeOutCubic,
              ),

          // Score text
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                score.toInt().toString(),
                style: Theme.of(context)
                    .textTheme
                    .displayLarge!
                    .copyWith(
                      color: AppColor.neonGreen,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1,
                    ),
              ).animate().scale(
                    duration: 600.ms,
                    delay: 300.ms,
                    curve: Curves.easeOutBack,
                  ),
              const SizedBox(height: 2),
              Text(
                'Authenticity',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: AppColor.textDim,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GaugeTrackPainter extends CustomPainter {
  final double radius;
  final double strokeWidth;
  final double scoreFraction;

  _GaugeTrackPainter({
    required this.radius,
    required this.strokeWidth,
    required this.scoreFraction,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerOffset = Offset(size.width / 2, size.height / 2);

    // Background arc
    final bgPaint = Paint()
      ..color = AppColor.divider.withValues(alpha: 0.5)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: centerOffset, radius: radius - strokeWidth / 2),
      -1.5,
      3.0 * 3.14159,
      false,
      bgPaint,
    );

    // Score arc
    final scorePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColor.neonGreen,
          AppColor.neonGreenDim,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(
        Rect.fromCircle(center: centerOffset, radius: radius),
      )
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 3.0 * 3.14159 * scoreFraction;
    canvas.drawArc(
      Rect.fromCircle(center: centerOffset, radius: radius - strokeWidth / 2),
      -1.5,
      sweepAngle,
      false,
      scorePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugeTrackPainter oldDelegate) {
    return oldDelegate.scoreFraction != scoreFraction;
  }
}
