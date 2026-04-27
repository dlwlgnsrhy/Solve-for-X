import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sfx_memento_mori/core/theme/neon_colors.dart';
import 'package:sfx_memento_mori/core/utils/life_calculator.dart';

class WeekGrid extends StatefulWidget {
  final LifeStats lifeStats;

  const WeekGrid({super.key, required this.lifeStats});

  @override
  State<WeekGrid> createState() => _WeekGridState();
}

class _WeekGridState extends State<WeekGrid> {
  static const int columns = 20;

  // Max cells that get staggered entrance animations (performance optimization)
  static const int maxAnimatedCells = 100;

  // Major decade markers: 10, 20, 30, 40, 50, 60, 70
  static const List<int> decadeMarkers = [10, 20, 30, 40, 50, 60, 70];

  // Milestone years: 18, 25, 30, 60, 65, 70
  static const List<int> milestoneMarkers = [18, 25, 30, 60, 65, 70];

  @override
  Widget build(BuildContext context) {
    final totalWeeks = widget.lifeStats.totalWeeks;
    final totalRows = (totalWeeks / columns).ceil();
    final currentWeekIndex = widget.lifeStats.currentWeekIndex;
    final currentAge = widget.lifeStats.currentAge;

    // Calculate year marker positions (every 10 years = 520 weeks)
    final yearMarkers = <int>[];
    for (final age in decadeMarkers) {
      final weekIndex = age * 52;
      if (weekIndex < totalWeeks) {
        yearMarkers.add(weekIndex);
      }
    }

    // Calculate milestone marker positions
    final milestoneWeeks = <int>[];
    for (final age in milestoneMarkers) {
      final weekIndex = age * 52;
      if (weekIndex < totalWeeks) {
        milestoneWeeks.add(weekIndex);
      }
    }

    // Calculate current age row
    final currentAgeRow = (currentAge * 52) ~/ columns;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Remaining weeks message with large typography
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '남은 시간',
                  style: TextStyle(
                    color: NeonColors.neonGreen.withValues(alpha: 0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 2,
                  ),
                ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.3, end: 0),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _formatNumber(widget.lifeStats.remainingWeeks),
                      style: TextStyle(
                        color: NeonColors.neonGreen,
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1,
                        shadows: [
                          Shadow(
                            color: NeonColors.glowGreen,
                            blurRadius: 20,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                    ).animate(
                      onPlay: (ctrl) => ctrl.repeat(period: 2.5.seconds),
                    ).fadeIn(duration: 800.ms).slideY(begin: -0.5, end: 0)
                        .scale(begin: const Offset(0.98, 0.98), end: const Offset(1, 1), duration: 1.seconds),
                    const SizedBox(width: 8),
                    Text(
                      '주',
                      style: TextStyle(
                        color: NeonColors.neonGreen.withValues(alpha: 0.8),
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ).animate().fadeIn(duration: 800.ms, delay: 200.ms),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '총 ${_formatNumber(widget.lifeStats.totalWeeks)}주 중 ${_formatNumber(widget.lifeStats.elapsedWeeks)}주가 지났습니다',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                  ),
                ).animate().fadeIn(duration: 800.ms, delay: 300.ms).slideY(begin: -0.3, end: 0),
                const SizedBox(height: 4),
                Text(
                  '"오늘을 소중히, 그 순간순간이 당신의 전부입니다"',
                  style: TextStyle(
                    color: NeonColors.neonCyan.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ).animate().fadeIn(duration: 800.ms, delay: 400.ms),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Year markers row
          if (yearMarkers.isNotEmpty)
            _buildYearMarkers(yearMarkers, totalRows),

          // Grid with year marker overlays -- wrapped in RepaintBoundary
          Expanded(
            child: RepaintBoundary(
              child: _buildGridWithMarkers(
                totalRows: totalRows,
                yearMarkers: yearMarkers,
                milestoneWeeks: milestoneWeeks,
                currentAgeRow: currentAgeRow,
                currentWeekIndex: currentWeekIndex,
              ),
            ),
          ).animate().fadeIn(duration: 1000.ms, delay: 200.ms),

          // Legend
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendItem(color: NeonColors.pastWeek, label: '지난 주'),
                const SizedBox(width: 12),
                _LegendItem(color: NeonColors.todayPulse, label: '오늘'),
                const SizedBox(width: 12),
                _LegendItem(color: NeonColors.neonGreen, label: '남은 주'),
                const SizedBox(width: 12),
                _LegendItem(
                  color: NeonColors.currentAgeHighlight,
                  label: '현재 나이',
                ),
              ],
            ),
          ).animate().fadeIn(duration: 600.ms, delay: 600.ms),
        ],
      ),
    );
  }

  Widget _buildYearMarkers(List<int> yearMarkers, int totalRows) {
    return SizedBox(
      height: 20,
      child: Stack(
        children: [
          // Background line
          Positioned(
            left: 0,
            right: 0,
            top: 10,
            child: Container(
              height: 1,
              color: NeonColors.yearMarker.withValues(alpha: 0.3),
            ),
          ),
          // Year labels
          ...yearMarkers.map((weekIndex) {
            final col = weekIndex % columns;
            final age = weekIndex ~/ 52;
            return Positioned(
              left: (col / columns) * MediaQuery.of(context).size.width *
                      (1 - 24 / MediaQuery.of(context).size.width) -
                  12,
              top: 0,
              child: Text(
                '$age세',
                style: TextStyle(
                  color: NeonColors.yearMarker.withValues(alpha: 0.6),
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 400.ms);
  }

  /// Builds the grid using ListView.builder for rows of weeks (performance).
  /// Each row is a RepaintBoundary to isolate repaints.
  Widget _buildGridWithMarkers({
    required int totalRows,
    required List<int> yearMarkers,
    required List<int> milestoneWeeks,
    required int currentAgeRow,
    required int currentWeekIndex,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gridWidth = constraints.maxWidth - 24;
        final cellSpacing = 2.0;
        final cellSize = (gridWidth - cellSpacing * (columns - 1)) / columns;
        final rowHeight = cellSize + cellSpacing;

        return CustomPaint(
          size: Size(constraints.maxWidth, totalRows * rowHeight),
          painter: YearMarkerPainter(
            yearMarkers: yearMarkers,
            milestoneWeeks: milestoneWeeks,
            currentAgeRow: currentAgeRow,
            columns: columns,
            cellSpacing: cellSpacing,
            cellSize: cellSize,
            totalRows: totalRows,
          ),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const ClampingScrollPhysics(),
            itemCount: totalRows,
            itemExtent: rowHeight,
            itemBuilder: (context, rowIndex) {
              final firstIndex = rowIndex * columns;
              final lastIndex = (firstIndex + columns).clamp(0, widget.lifeStats.totalWeeks);
              final rowWeekCount = lastIndex - firstIndex;

              return RepaintBoundary(
                child: Row(
                  children: List.generate(rowWeekCount, (colOffset) {
                    final index = firstIndex + colOffset;
                    final isPast = index < widget.lifeStats.elapsedWeeks;
                    final isToday = index == currentWeekIndex;
                    // Only apply staggered animation for first N cells
                    final animateEntrance = index < maxAnimatedCells;

                    Widget cell = _WeekCell(
                      isPast: isPast,
                      isToday: isToday,
                      index: index,
                    );

                    if (animateEntrance) {
                      cell = cell
                          .animate()
                          .fadeIn(duration: 300.ms, delay: (index * 4).ms)
                          .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1), duration: 300.ms);
                    }

                    return SizedBox(width: cellSize, height: cellSize, child: cell);
                  }),
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}

class YearMarkerPainter extends CustomPainter {
  final List<int> yearMarkers;
  final List<int> milestoneWeeks;
  final int currentAgeRow;
  final int columns;
  final double cellSpacing;
  final double cellSize;
  final int totalRows;

  YearMarkerPainter({
    required this.yearMarkers,
    required this.milestoneWeeks,
    required this.currentAgeRow,
    required this.columns,
    required this.cellSpacing,
    required this.cellSize,
    required this.totalRows,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rowHeight = cellSize + cellSpacing;

    // Draw year marker lines (decade markers)
    final decadePaint = Paint()
      ..color = NeonColors.yearMarker.withValues(alpha: 0.2)
      ..strokeWidth = 1;

    for (final weekIndex in yearMarkers) {
      final row = weekIndex ~/ columns;
      final y = row * rowHeight + cellSize / 2;

      if (y > 0 && y < size.height) {
        canvas.drawLine(
          Offset(0, y),
          Offset(size.width, y),
          decadePaint,
        );
      }
    }

    // Draw current age highlight line (subtle neon cyan)
    if (currentAgeRow >= 0 && currentAgeRow < totalRows) {
      final currentAgeY = currentAgeRow * rowHeight + cellSize / 2;

      // Glow effect
      final glowPaint = Paint()
        ..color = NeonColors.currentAgeHighlight.withValues(alpha: 0.08)
        ..strokeWidth = rowHeight * 1.5;

      canvas.drawLine(
        Offset(0, currentAgeY),
        Offset(size.width, currentAgeY),
        glowPaint,
      );

      // Main line
      final linePaint = Paint()
        ..color = NeonColors.currentAgeHighlight.withValues(alpha: 0.5)
        ..strokeWidth = 1.5;

      canvas.drawLine(
        Offset(0, currentAgeY),
        Offset(size.width, currentAgeY),
        linePaint,
      );
    }

    // Draw milestone labels (18, 25, 30, 60, 65, 70)
    for (final weekIndex in milestoneWeeks) {
      final row = weekIndex ~/ columns;
      final y = row * rowHeight + cellSize / 2;
      final age = weekIndex ~/ 52;

      if (y > 0 && y < size.height) {
        final text = '$age세';
        final textPainter = TextPainter(
          text: TextSpan(
            text: text,
            style: TextStyle(
              color: NeonColors.currentAgeHighlight.withValues(alpha: 0.4),
              fontSize: 8,
              fontWeight: FontWeight.w500,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(size.width - textPainter.width - 4, y - textPainter.height / 2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant YearMarkerPainter oldDelegate) => false;
}

class _WeekCell extends StatefulWidget {
  final bool isPast;
  final bool isToday;
  final int index;

  const _WeekCell({
    required this.isPast,
    required this.isToday,
    required this.index,
  });

  @override
  State<_WeekCell> createState() => _WeekCellState();
}

class _WeekCellState extends State<_WeekCell>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    // Only create animation controller for today's cell
    if (widget.isToday) {
      _pulseController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1500),
      )..repeat(reverse: true);
      _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
      );
    } else {
      _pulseController = AnimationController(vsync: this);
      _pulseAnimation = const AlwaysStoppedAnimation(1.0);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isToday) {
      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              color: NeonColors.todayPulse,
              borderRadius: BorderRadius.circular(3),
              boxShadow: [
                BoxShadow(
                  color: NeonColors.todayPulse.withValues(
                    alpha: 0.6 * _pulseAnimation.value,
                  ),
                  blurRadius: 8 * _pulseAnimation.value,
                  spreadRadius: 1 * _pulseAnimation.value,
                ),
                BoxShadow(
                  color: NeonColors.neonGreen.withValues(
                    alpha: 0.3 * _pulseAnimation.value,
                  ),
                  blurRadius: 12 * _pulseAnimation.value,
                  spreadRadius: 0,
                ),
              ],
            ),
          );
        },
      );
    } else if (widget.isPast) {
      // StatelessWidget-equivalent: plain Container with no extra overhead
      return Container(
        decoration: BoxDecoration(
          color: NeonColors.pastWeek,
          borderRadius: BorderRadius.circular(3),
        ),
      );
    } else {
      // Future weeks: simplified no-shadow for performance
      return Container(
        decoration: BoxDecoration(
          color: NeonColors.neonGreen.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(3),
        ),
      );
    }
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            boxShadow: color == NeonColors.todayPulse
                ? [
                    BoxShadow(
                      color: NeonColors.todayPulse.withValues(alpha: 0.4),
                      blurRadius: 6,
                    ),
                  ]
                : color == NeonColors.neonGreen
                    ? [
                        BoxShadow(
                          color: NeonColors.neonGreen.withValues(alpha: 0.3),
                          blurRadius: 4,
                        ),
                      ]
                    : null,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white54,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
