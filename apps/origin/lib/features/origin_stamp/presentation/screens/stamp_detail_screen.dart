import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:origin/core/theme/app_theme.dart';
import 'package:origin/features/home/presentation/widgets/score_gauge.dart';

/// Screen showing details for a specific origin stamp.
///
/// Displays the authenticity score from this stamp alongside the
/// content hash, timestamp, event count, and per-session metrics.
class StampDetailScreen extends StatefulWidget {
  /// Raw database stamp record.
  final Map<String, dynamic> stamp;

  const StampDetailScreen({super.key, required this.stamp});

  @override
  State<StampDetailScreen> createState() => _StampDetailScreenState();
}

class _StampDetailScreenState extends State<StampDetailScreen> {
  bool _isLoading = true;
  double _score = 0.0;
  double _rhythmEntropy = 0.0;
  double _revisionPattern = 0.0;
  String _avgResponseTime = '--';
  String _backspaceRatio = '--';
  String _typeTokenRatio = '--';

  @override
  void initState() {
    super.initState();
    _score =
        (widget.stamp['authenticity_score'] as num?)?.toDouble() ?? 0.0;
    _rhythmEntropy =
        (widget.stamp['rhythm_entropy'] as num?)?.toDouble() ?? 0.0;
    _revisionPattern =
        (widget.stamp['revision_pattern_score'] as num?)?.toDouble() ??
            0.0;
  }

  // ignore: unused_element
  Future<void> _loadSessionMetrics() async {
    // TODO: wire up DB injection after the home provider refactor.
    try {
      final sessionId =
          widget.stamp['session_id'] as String? ?? '';
      if (sessionId.isEmpty) return;

      final db = await _getDb();
      final events = await db.getEventsForSession(sessionId);

      if (!mounted) return;

      if (events.isNotEmpty) {
        final tdeltas = events
            .map((e) => (e['t_delta'] as num?)?.toDouble() ?? 0)
            .toList();
        if (tdeltas.isNotEmpty) {
          final avg = tdeltas.reduce((a, b) => a + b) /
              tdeltas.length;
          _avgResponseTime = '${avg.round()}ms';
        }

        int backspaceCount = 0;
        for (final event in events) {
          if ((event['is_backspace'] as int?) == 1) {
            backspaceCount++;
          }
        }
        if (events.length > 0) {
          _backspaceRatio =
              '${((backspaceCount / events.length) * 100).toStringAsFixed(1)}%';
        }

        final uniqueKeys =
            events.map((e) => e['key_name'] as String).toSet().length;
        _typeTokenRatio = events.isNotEmpty
            ? (uniqueKeys / events.length)
                .toStringAsFixed(2)
            : '--';
      }
    } catch (e) {
      debugPrint('[StampDetailScreen] Error loading metrics: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<dynamic> _getDb() async {
    // Lazy-load DatabaseService import to avoid circular dependency.
    // In a real codebase this would be injected via DI.
    // We use a dynamic export to the shared service.
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context);
    final contentHash = widget.stamp['content_hash'] as String? ?? '--';
    final timestamp = widget.stamp['timestamp'] as String? ?? '--';
    final eventCount =
        (widget.stamp['keystroke_event_count'] as num?)?.toInt() ?? 0;

    return Scaffold(
      backgroundColor: AppColor.bgPrimary,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColor.textPrimary, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Stamp Details',
          style: TextStyle(
            color: AppColor.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Text(
                    'Origin Stamp',
                    style: style.textTheme.headlineMedium!.copyWith(
                      color: AppColor.textPrimary,
                    ),
                  ).animate().fadeIn(duration: 400.ms),
                  const SizedBox(height: 48),
                  ScoreGauge(score: _score).animate().scale(
                        duration: 800.ms,
                        delay: 300.ms,
                        curve: Curves.easeOutCubic,
                      ),
                  const SizedBox(height: 32),

                  // Metric cards
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _metricCard(
                          'Rhythm Entropy',
                          _rhythmEntropy.toStringAsFixed(3),
                          style),
                      _metricCard(
                          'Revision Pattern',
                          _revisionPattern.toStringAsFixed(3),
                          style),
                      _metricCard('Avg Response', _avgResponseTime, style),
                      _metricCard('Backspace Ratio', _backspaceRatio,
                          style),
                      _metricCard(
                          'Type-Token Ratio', _typeTokenRatio, style),
                    ],
                  ).animate().slide(begin: const Offset(0, 0.15))
                      .fadeIn(delay: 800.ms),
                  const SizedBox(height: 32),

                  // Metadata
                  _metadataCard('Content Hash', contentHash, style),
                  const SizedBox(height: 12),
                  _metadataCard('Timestamp', timestamp, style),
                  const SizedBox(height: 12),
                  _metadataCard(
                      'Events Recorded', eventCount.toString(), style),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _metricCard(String label, String value, ThemeData style) {
    return Container(
      width: 150,
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColor.bgSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColor.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: style.textTheme.bodySmall!.copyWith(
              color: AppColor.textDim,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: style.textTheme.titleLarge!.copyWith(
              color: AppColor.neonGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metadataCard(
      String label, String value, ThemeData style) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColor.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColor.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: style.textTheme.bodySmall!.copyWith(
              color: AppColor.textDim,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: style.textTheme.bodyMedium!.copyWith(
              color: AppColor.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 1000.ms);
  }
}
