import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sfx_memento_mori/core/services/review_service.dart';
import 'package:sfx_memento_mori/core/theme/neon_colors.dart';
import 'package:sfx_memento_mori/core/utils/life_calculator.dart';
import 'package:sfx_memento_mori/core/utils/life_quotes.dart';
import 'package:sfx_memento_mori/features/home/presentation/providers/life_provider.dart';
import 'package:sfx_memento_mori/features/home/presentation/widgets/week_grid.dart';
import 'package:sfx_memento_mori/features/settings/presentation/pages/settings_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with SingleTickerProviderStateMixin {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isSharing = false;

  // Animated counter for remaining weeks
  late AnimationController _counterController;
  int _displayWeeks = 0;

  @override
  void initState() {
    super.initState();
    _checkReviewPrompt();

    _counterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  Future<void> _checkReviewPrompt() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final reviewService = ref.read(reviewServiceProvider);
    if (reviewService.shouldPromptReview()) {
      await reviewService.promptReview();
    }
  }

  /// Start the animated counter for remaining weeks
  void _animateRemainingWeeks(int targetWeeks) {
    if (targetWeeks == 0) return;

    _displayWeeks = 0;
    _counterController.forward(from: 0.0);

    final startTime = DateTime.now();
    final duration = _counterController.duration!.inMilliseconds;

    void tick() {
      if (!mounted) return;
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      final progress = (elapsed / duration).clamp(0.0, 1.0);
      final easedProgress = 1 - math.pow(1 - progress, 3);
      setState(() {
        _displayWeeks = (targetWeeks * easedProgress).round();
      });
      if (progress < 1.0) {
        Future.delayed(const Duration(milliseconds: 16), tick);
      }
    }
    tick();
  }

  Future<void> _shareGrid() async {
    setState(() => _isSharing = true);

    try {
      final lifeStats = ref.read(lifeProvider);
      final progress = lifeStats?.completionPercentage ?? 0;
      final caption = LifeQuotes.getShareCaption(progress);
      final quote = LifeQuotes.getQuote(progress);

      final image = await _screenshotController.capture(pixelRatio: 3.0);
      if (image == null) return;

      final originalImage = await decodeImageFromList(image);
      final framePadding = 40.0;
      final bottomPadding = 200.0;
      final targetWidth = originalImage.width + (framePadding * 2);
      final targetHeight = originalImage.height + framePadding + bottomPadding;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      final bgPaint = Paint()..color = NeonColors.background;
      canvas.drawRect(
        Rect.fromLTWH(0, 0, targetWidth, targetHeight),
        bgPaint,
      );

      final topAccentPaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, 0),
          Offset(0, 60),
          [
            NeonColors.neonGreen.withValues(alpha: 0.15),
            NeonColors.neonGreen.withValues(alpha: 0.0),
          ],
        );
      canvas.drawRect(
        Rect.fromLTWH(0, 0, targetWidth, 60),
        topAccentPaint,
      );

      final framePaint = Paint()
        ..color = NeonColors.neonGreen.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawRect(
        Rect.fromLTWH(8, 8, targetWidth - 16, targetHeight - 16),
        framePaint,
      );

      final cornerPaint = Paint()
        ..color = NeonColors.neonGreen
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      const cornerLength = 20.0;
      canvas.drawLine(Offset(8, 8 + cornerLength), Offset(8, 8), cornerPaint);
      canvas.drawLine(Offset(8, 8), Offset(8 + cornerLength, 8), cornerPaint);
      canvas.drawLine(
        Offset(targetWidth - 8 - cornerLength, 8),
        Offset(targetWidth - 8, 8),
        cornerPaint,
      );
      canvas.drawLine(
        Offset(targetWidth - 8, 8),
        Offset(targetWidth - 8, 8 + cornerLength),
        cornerPaint,
      );
      canvas.drawLine(
        Offset(8, targetHeight - 8 - cornerLength),
        Offset(8, targetHeight - 8),
        cornerPaint,
      );
      canvas.drawLine(
        Offset(8, targetHeight - 8),
        Offset(8 + cornerLength, targetHeight - 8),
        cornerPaint,
      );
      canvas.drawLine(
        Offset(targetWidth - 8 - cornerLength, targetHeight - 8),
        Offset(targetWidth - 8, targetHeight - 8),
        cornerPaint,
      );
      canvas.drawLine(
        Offset(targetWidth - 8, targetHeight - 8),
        Offset(targetWidth - 8, targetHeight - 8 - cornerLength),
        cornerPaint,
      );

      final imgRect = Rect.fromLTWH(
        framePadding,
        framePadding,
        originalImage.width.toDouble(),
        originalImage.height.toDouble(),
      );
      canvas.drawImageRect(
        originalImage,
        Rect.fromLTWH(0, 0, originalImage.width.toDouble(), originalImage.height.toDouble()),
        imgRect,
        Paint(),
      );

      final bottomY = framePadding + originalImage.height + 20;

      if (lifeStats != null) {
        final statsX = framePadding + 10;
        final statsWidth = targetWidth - framePadding * 2 - 20;

        final statsBgPaint = Paint()
          ..color = NeonColors.surface.withValues(alpha: 0.5)
          ..style = PaintingStyle.fill;
        final roundedRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(statsX, bottomY, statsWidth, 50),
          const Radius.circular(8),
        );
        canvas.drawRRect(roundedRect, statsBgPaint);

        final statsBorderPaint = Paint()
          ..color = NeonColors.statsBorder
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
        canvas.drawRRect(roundedRect, statsBorderPaint);

        final statsText = TextPainter(
          text: TextSpan(
            text: '${lifeStats.currentAge}세  •  ${_formatNumber(lifeStats.elapsedWeeks)}주 경과  •  ${_formatNumber(lifeStats.remainingWeeks)}주 남음  •  ${(progress * 100).toStringAsFixed(1)}% 진행',
            style: TextStyle(
              color: NeonColors.neonGreen.withValues(alpha: 0.9),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
          maxLines: 1,
          ellipsis: '...',
        );
        statsText.layout();
        statsText.paint(canvas, Offset(statsX + 12, bottomY + 17));

        final quotePainter = TextPainter(
          text: TextSpan(
            text: '"$quote"',
            style: TextStyle(
              color: NeonColors.neonCyan.withValues(alpha: 0.7),
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        quotePainter.layout();
        quotePainter.paint(
          canvas,
          Offset(
            (targetWidth - quotePainter.width) / 2,
            bottomY + 58,
          ),
        );

        final dividerPaint = Paint()
          ..color = NeonColors.statsBorder
          ..strokeWidth = 1;
        canvas.drawLine(
          Offset(targetWidth * 0.2, bottomY + 85),
          Offset(targetWidth * 0.8, bottomY + 85),
          dividerPaint,
        );

        final logoPainter = TextPainter(
          text: TextSpan(
            text: 'SFX MEMENTO MORI',
            style: TextStyle(
              color: NeonColors.neonGreen,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 5,
              shadows: [
                Shadow(
                  color: NeonColors.glowGreen,
                  blurRadius: 10,
                ),
              ],
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        logoPainter.layout();
        logoPainter.paint(
          canvas,
          Offset((targetWidth - logoPainter.width) / 2, bottomY + 95),
        );

        final subtitlePainter = TextPainter(
          text: TextSpan(
            text: '인생을 주간으로 시각화',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        subtitlePainter.layout();
        subtitlePainter.paint(
          canvas,
          Offset((targetWidth - subtitlePainter.width) / 2, bottomY + 118),
        );

        final storePainter = TextPainter(
          text: TextSpan(
            text: 'App Store에서 다운로드',
            style: TextStyle(
              color: NeonColors.neonCyan.withValues(alpha: 0.5),
              fontSize: 9,
              letterSpacing: 1,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        storePainter.layout();
        storePainter.paint(
          canvas,
          Offset((targetWidth - storePainter.width) / 2, bottomY + 138),
        );

        final footerPainter = TextPainter(
          text: TextSpan(
            text: '© 2025 SFX  •  sfxmemento.com',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 9,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        footerPainter.layout();
        footerPainter.paint(
          canvas,
          Offset((targetWidth - footerPainter.width) / 2, bottomY + 158),
        );
      } else {
        final logoPainter = TextPainter(
          text: TextSpan(
            text: 'SFX MEMENTO MORI',
            style: TextStyle(
              color: NeonColors.neonGreen,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
              shadows: [
                Shadow(
                  color: NeonColors.glowGreen,
                  blurRadius: 10,
                ),
              ],
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        logoPainter.layout();
        logoPainter.paint(
          canvas,
          Offset((targetWidth - logoPainter.width) / 2, bottomY),
        );

        final captionPainter = TextPainter(
          text: TextSpan(
            text: caption,
            style: TextStyle(
              color: NeonColors.neonCyan.withValues(alpha: 0.7),
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        captionPainter.layout();
        captionPainter.paint(
          canvas,
          Offset(
            (targetWidth - captionPainter.width) / 2,
            bottomY + 28,
          ),
        );

        final footerPainter = TextPainter(
          text: TextSpan(
            text: '© 2025 SFX',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 10,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        footerPainter.layout();
        footerPainter.paint(
          canvas,
          Offset((targetWidth - footerPainter.width) / 2, bottomY + 58),
        );
      }

      final picture = recorder.endRecording();
      final framedImage = await picture.toImage(
        targetWidth.toInt(),
        targetHeight.toInt(),
      );
      final byteData = await framedImage.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData?.buffer.asUint8List();
      if (bytes == null) return;

      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'memento_mori_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);

      if (mounted) {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: '내 인생의 그리드 - SFX Memento Mori\n\n인생은 총 4,160주. 당신의 남은 시간은 얼마인가요?\n\nApp Store에서 SFX Memento Mori를 다운로드하세요.',
        );
      }
    } catch (e) {
      debugPrint('Share error: $e');
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  void dispose() {
    _counterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lifeStats = ref.watch(lifeProvider);

    // Animate counter when life stats are available
    if (lifeStats != null && _counterController.isDismissed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _animateRemainingWeeks(lifeStats.remainingWeeks);
      });
    }

    return Screenshot(
      controller: _screenshotController,
      child: Scaffold(
        backgroundColor: NeonColors.background,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(context, ref),
              const SizedBox(height: 12),

              // Today's week badge
              if (lifeStats != null)
                _buildTodayBadge(lifeStats)
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 100.ms)
                    .slideY(begin: -0.5, end: 0, duration: 500.ms),
              if (lifeStats != null) const SizedBox(height: 8),

              // Premium stats card
              if (lifeStats != null)
                _buildPremiumStats(context, lifeStats)
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: -0.3, end: 0, duration: 600.ms),
              if (lifeStats != null) const SizedBox(height: 16),

              // Week grid
              Expanded(
                child: lifeStats != null
                    ? WeekGrid(lifeStats: lifeStats)
                    : const Center(
                        child: Text(
                          '로딩 중...',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// "오늘의 주" badge highlighting current week
  Widget _buildTodayBadge(LifeStats lifeStats) {
    final currentWeekIndex = lifeStats.currentWeekIndex;
    final totalWeeks = lifeStats.totalWeeks;
    final weekOfYear = (DateTime.now().difference(
      DateTime(DateTime.now().year, 1, 1),
    ).inDays ~/ 7 + 1);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: NeonColors.todayPulse.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: NeonColors.todayPulse.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: NeonColors.todayPulse.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.star_border,
            color: NeonColors.todayPulse,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            '오늘의 주',
            style: TextStyle(
              color: NeonColors.todayPulse,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: NeonColors.todayPulse.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '#${currentWeekIndex + 1}',
              style: TextStyle(
                color: NeonColors.todayPulse,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '/ $totalWeeks',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
          const Spacer(),
          Text(
            '년 $weekOfYear주째',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MEMENTO MORI',
                style: TextStyle(
                  color: NeonColors.neonGreen,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                  shadows: [
                    Shadow(
                      color: NeonColors.glowGreen,
                      blurRadius: 10,
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 2),
              Text(
                '일상적 죽음의 기억',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  letterSpacing: 1,
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
            ],
          ),
          Row(
            children: [
              // Share button
              IconButton(
                icon: Icon(
                  _isSharing ? Icons.check_circle : Icons.share_outlined,
                  color: _isSharing ? NeonColors.neonGreen : Colors.white54,
                  size: 22,
                ),
                onPressed: _isSharing ? null : _shareGrid,
                tooltip: '내 인생 공유하기',
              ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
              // Settings button
              IconButton(
                icon: const Icon(
                  Icons.settings_outlined,
                  color: Colors.white54,
                  size: 22,
                ),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                ),
                tooltip: '설정',
              ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumStats(BuildContext context, LifeStats lifeStats) {
    final progress = lifeStats.completionPercentage;
    final quote = LifeQuotes.getTimeBasedQuote();
    final remainingDays = lifeStats.remainingDays;
    final elapsedYears = lifeStats.elapsedYears;
    final elapsedMonths = lifeStats.elapsedMonths;
    final timeLabel = LifeQuotes.getTimeOfDayLabel();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NeonColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: NeonColors.statsBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: NeonColors.neonGreen.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Circular progress + main stats
          Row(
            children: [
              // Circular progress indicator (larger)
              _CircularProgressIndicator(
                progress: progress,
                size: 72,
              ).animate()
                  .fadeIn(duration: 800.ms, delay: 200.ms)
                  .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
              const SizedBox(width: 16),
              // Main stats
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Remaining weeks with animated counter
                    Row(
                      children: [
                        Text(
                          '남은 ',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            '$_displayWeeks주',
                            style: TextStyle(
                              color: NeonColors.neonGreen,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: NeonColors.glowGreen,
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ).animate(
                      onPlay: (ctrl) => ctrl.repeat(period: 3.seconds),
                    ).fadeIn(duration: 800.ms, delay: 300.ms),
                    const SizedBox(height: 4),
                    // Progress percentage
                    Text(
                      '인생 진행률: ${(progress * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: NeonColors.neonCyan,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ).animate().fadeIn(duration: 600.ms, delay: 350.ms),
                    // Time of day label
                    Text(
                      timeLabel,
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ).animate().fadeIn(duration: 600.ms, delay: 400.ms),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: NeonColors.statsBorder, height: 1),
          const SizedBox(height: 12),

          // Detailed stats row
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _StatChip(
                            label: '지난 주',
                            value: _formatNumber(lifeStats.elapsedWeeks),
                            color: NeonColors.neonPink,
                          ).animate().fadeIn(duration: 600.ms, delay: 400.ms),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatChip(
                            label: '남은 일수',
                            value: _formatNumber(remainingDays),
                            color: NeonColors.neonCyan,
                          ).animate().fadeIn(duration: 600.ms, delay: 450.ms),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _StatChip(
                            label: '지금까지 산 시간',
                            value: '$elapsedYears년 $elapsedMonths개월',
                            color: NeonColors.neonGreen,
                          ).animate().fadeIn(duration: 600.ms, delay: 500.ms),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatChip(
                            label: '현재 나이',
                            value: '${lifeStats.currentAge}세',
                            color: NeonColors.todayPulse,
                          ).animate().fadeIn(duration: 600.ms, delay: 550.ms),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Time-of-day motivational quote
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: NeonColors.neonCyan.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: NeonColors.neonCyan.withValues(alpha: 0.15),
                width: 0.5,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: NeonColors.neonCyan.withValues(alpha: 0.5),
                  size: 14,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    quote,
                    style: TextStyle(
                      color: NeonColors.neonCyan.withValues(alpha: 0.6),
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 600.ms, delay: 600.ms),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}

class _CircularProgressIndicator extends StatelessWidget {
  final double progress;
  final double size;

  const _CircularProgressIndicator({
    required this.progress,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ProgressPainter(
          progress: progress.clamp(0.0, 1.0),
          bgColor: NeonColors.darkGrey,
          progressColor: NeonColors.neonGreen,
          glowColor: NeonColors.glowGreen,
          textColor: Colors.white,
          textSize: size * 0.28,
        ),
      ),
    );
  }
}

class _ProgressPainter extends CustomPainter {
  final double progress;
  final Color bgColor;
  final Color progressColor;
  final Color glowColor;
  final Color textColor;
  final double textSize;

  _ProgressPainter({
    required this.progress,
    required this.bgColor,
    required this.progressColor,
    required this.glowColor,
    required this.textColor,
    required this.textSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;

    // Glow effect
    final glowPaint = Paint()
      ..color = glowColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = ui.StrokeCap.round;

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        math.pi * 2 * progress,
        false,
        glowPaint,
      );
    }

    // Background circle
    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = ui.StrokeCap.round;

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        math.pi * 2 * progress,
        false,
        progressPaint,
      );
    }

    // Text
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${(progress * 100).toStringAsFixed(0)}%',
        style: TextStyle(
          color: textColor,
          fontSize: textSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white54,
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
