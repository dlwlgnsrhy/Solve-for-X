import 'dart:math' as math;

/// Rhythm Entropy Metric: Shannon entropy of typing inter-key time deltas.
///
/// Bucket-wise distribution into 5 time ranges, normalized by log2(5):
///   entropy = -Σ p_i * log2(p_i) / log2(5)
/// Range: [0.0, 1.0] where 1.0 = perfectly uniform across all buckets.
class RhythmEntropyMetric {
  /// Compute rhythm entropy normalized to [0.0, 1.0].
  ///
  /// Buckets: ≤50ms, ≤100ms, ≤200ms, ≤500ms, >500ms.
  static double compute(List<double> tdeltas) {
    if (tdeltas.isEmpty) return 0.0;

    final buckets = [0, 0, 0, 0, 0];
    for (final t in tdeltas) {
      if (t <= 50) {
        buckets[0]++;
      } else if (t <= 100) {
        buckets[1]++;
      } else if (t <= 200) {
        buckets[2]++;
      } else if (t <= 500) {
        buckets[3]++;
      } else {
        buckets[4]++;
      }
    }

    double entropy = 0.0;
    for (final count in buckets) {
      if (count > 0) {
        final p = count / tdeltas.length;
        entropy -= p * (math.log(p) / math.log(2));
      }
    }

    final maxEntropy = math.log(5) / math.log(2);
    return maxEntropy > 0 ? entropy / maxEntropy : 0.0;
  }
}
