import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:origin/core/services/database_service.dart';
import 'package:origin/core/theme/app_theme.dart';
import 'package:origin/features/authentic_analyzer/presentation/widgets/fingerprint_view.dart';
import 'score_gauge.dart';

/// Page displaying the authenticity score with live metrics from the latest stamp.
class AuthenticityScorePage extends StatefulWidget {
  const AuthenticityScorePage({super.key});

  @override
  State<AuthenticityScorePage> createState() =>
      _AuthenticityScorePageState();
}

class _AuthenticityScorePageState extends State<AuthenticityScorePage> {
  double _score = 0.0;
  double _rhythmEntropy = 0.0;
  double _revisionPattern = 0.0;
  String _avgResponseTime = '--';
  String _backspaceRatio = '--';
  String _typeTokenRatio = '--';
  Map<String, dynamic>? _fingerprint;
  bool _isLoading = true;
  final List<String> _errors = [];

  @override
  void initState() {
    super.initState();
    _loadLatestStamp();
  }

  Future<void> _loadLatestStamp() async {
    try {
      final stamps = await globalDatabaseService.getAllStamps();

      if (mounted) {
        if (stamps.isEmpty) {
          _errors.add('No stamps found. Complete a document to generate one.');
          setState(() => _isLoading = false);
          return;
        }

        // Get the most recent stamp (queries are DESC order)
        final latest = stamps.first;
        final score = (latest['authenticity_score'] as num?)?.toDouble() ?? 0.0;
        final rhythm = (latest['rhythm_entropy'] as num?)?.toDouble() ?? 0.0;
        final revision = (latest['revision_pattern_score'] as num?)?.toDouble() ?? 0.0;

        // Get events for additional metrics
        final sessionId = latest['session_id'] as String? ?? '';
        String avgRTI = '--';
        String backspaceRatio = '--';
        String typeTokenRatio = '--';

        if (sessionId.isNotEmpty) {
          final events =
              await globalDatabaseService.getEventsForSession(sessionId);
          if (events.isNotEmpty) {
            final tdeltas = <num>[];
            int backspaceCount = 0;

            for (final event in events) {
              final td = event['t_delta'] as num?;
              if (td != null) tdeltas.add(td);
              if ((event['is_backspace'] as int?) == 1) {
                backspaceCount++;
              }
            }

            if (tdeltas.isNotEmpty) {
              final avg = tdeltas.reduce((a, b) => a + b) /
                  tdeltas.length;
              avgRTI = '${avg.round()}ms';
            }

            final totalEvents = events.length;
            if (totalEvents > 0) {
              final ratio = backspaceCount / totalEvents;
              backspaceRatio = '${(ratio * 100).toStringAsFixed(1)}%';
            }

            // Type-token ratio from unique keys used
            final uniqueKeys = events
                .map((e) => e['key_name'] as String)
                .toSet()
                .length;
            typeTokenRatio = events.isNotEmpty
                ? (uniqueKeys / events.length).toStringAsFixed(2)
                : '--';
          }
        }

        // Load fingerprint data (build if needed)
        Map<String, dynamic>? fingerprint;
        try {
          // Try to build fingerprint from completed sessions
          await globalDatabaseService.buildFingerprint();
          fingerprint = await globalDatabaseService.getFingerprint();
        } catch (e) {
          debugPrint('[AuthenticityScorePage] Fingerprint error: $e');
        }

        if (mounted) {
          setState(() {
            _isLoading = false;
            _score = score;
            _rhythmEntropy = rhythm;
            _revisionPattern = revision;
            _avgResponseTime = avgRTI;
            _backspaceRatio = backspaceRatio;
            _typeTokenRatio = typeTokenRatio;
            _fingerprint = fingerprint;
          });
        }
      }
    } catch (e) {
      debugPrint('[AuthenticityScorePage] Error: $e');
      if (mounted) {
        _errors.add('Failed to load: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Header
              Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, size: 22, color: AppColor.neonGreen),
                  const SizedBox(width: 10),
                  Text(
                    'Score',
                    style: style.textTheme.headlineMedium!.copyWith(
                      color: AppColor.textPrimary,
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms),

              const SizedBox(height: 48),

              // Loading
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_errors.isNotEmpty)
                // Error state
                Column(
                  children: [
                    Icon(Icons.error_outline_rounded, size: 48, color: AppColor.textDim),
                    const SizedBox(height: 12),
                    for (final error in _errors) ...[
                      Text(
                        error,
                        textAlign: TextAlign.center,
                        style: style.textTheme.bodyMedium!.copyWith(color: AppColor.textDim),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                )
              // Score view
              else
                _buildScoreContent(style),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreContent(ThemeData style) {
    return Column(
      children: [
        // Score gauge
        ScoreGauge(score: _score).animate().scale(
                          duration: 800.ms,
                          delay: 300.ms,
                          curve: Curves.easeOutCubic,
                        ),

        const SizedBox(height: 32),

        // Subtitle
        Text(
          'This is your mind at work.',
          textAlign: TextAlign.center,
          style: style.textTheme.headlineMedium!.copyWith(
            color: AppColor.neonGreen,
            fontWeight: FontWeight.w300,
            fontStyle: FontStyle.italic,
          ),
        ).animate().fadeIn(duration: 600.ms, delay: 600.ms),

        const SizedBox(height: 40),

        // Metric cards row 1
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _metricCard('Rhythm Entropy', _rhythmEntropy.toStringAsFixed(3), style),
            _metricCard('Revision Pattern', _revisionPattern.toStringAsFixed(3), style),
          ],
        ).animate().slide(begin: const Offset(0, 0.15))
            .fadeIn(delay: 800.ms),

        const SizedBox(height: 24),

        // Per-session metrics
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _metricCard('Avg Response Time', _avgResponseTime, style),
            _metricCard('Backspace Ratio', _backspaceRatio, style),
            _metricCard('Type-Token Ratio', _typeTokenRatio, style),
          ],
        ).animate().slide(begin: const Offset(0, 0.15))
            .fadeIn(delay: 1000.ms),

        const SizedBox(height: 24),

        // Long-term intellectual fingerprint
        if (_fingerprint != null) ...[
          FingerprintView(fingerprint: _fingerprint!).animate()
              .fadeIn(duration: 400.ms, delay: 1200.ms),
        ],
      ],
    );
  }

  Widget _metricCard(String label, String value, ThemeData style) {
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
}
