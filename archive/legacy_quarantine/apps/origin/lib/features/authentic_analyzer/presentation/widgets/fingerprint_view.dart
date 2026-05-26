import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:origin/core/theme/app_theme.dart';

/// Displays the user's intellectual fingerprint metrics.
class FingerprintView extends StatelessWidget {
  final Map<String, dynamic> fingerprint;

  const FingerprintView({super.key, required this.fingerprint});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context);
    final vocabRichness = _formatDecimal(fingerprint['vocabulary_richness'] as double?);
    final avgTDelta = _formatTDelta(fingerprint['avg_t_delta'] as double?);
    final revisionRatio = _formatDecimal(fingerprint['revision_ratio'] as double?);
    final functionWordRatio = _formatDecimal(fingerprint['function_word_ratio'] as double?);
    final sentLengthStddev = _formatDecimal(fingerprint['sentence_length_stddev'] as double?);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          'Your Intellectual Fingerprint',
          style: style.textTheme.titleMedium!.copyWith(
            color: AppColor.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 800.ms),

        const SizedBox(height: 12),

        // Metric cards row 2
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _metricCard('Vocabulary Richness', vocabRichness, style),
            _metricCard('Avg Response Time', avgTDelta, style),
            _metricCard('Revision Ratio', revisionRatio, style),
          ],
        ).animate().slide(begin: const Offset(0, 0.15))
            .fadeIn(delay: 1000.ms),

        const SizedBox(height: 12),

        // Row 3
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _metricCard('Function Word Ratio', functionWordRatio, style),
            _metricCard('Sentence Length Std Dev', sentLengthStddev, style),
          ],
        ).animate().slide(begin: const Offset(0, 0.15))
            .fadeIn(delay: 1200.ms),
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

  String _formatDecimal(double? value) {
    if (value == null) return '--';
    return value.toStringAsFixed(3);
  }

  String _formatTDelta(double? value) {
    if (value == null) return '--';
    return '${value.round()}ms';
  }
}
