import 'dart:math' as math;

/// Temporal Consistency Metric: Stability of typing rhythm.
///
/// Uses the coefficient of variation (CV) of inter-key time deltas:
///   cv = std(dev) / mean
///   score = 1.0 / (1.0 + cv)
/// Range: [0.0, 1.0] where 1.0 = perfectly consistent timing.
class TemporalConsistencyMetric {
  /// Compute temporal consistency score.
  ///
  /// [tdeltas] is the list of inter-key time deltas in milliseconds.
  static double compute(List<double> tdeltas) {
    if (tdeltas.isEmpty) return 0.5;

    final mean = tdeltas.reduce((a, b) => a + b) / tdeltas.length;
    if (mean <= 0) return 0.5;

    final variance = tdeltas
        .map((t) => math.pow(t - mean, 2))
        .reduce((a, b) => a + b) /
        tdeltas.length;
    final cv = math.sqrt(variance) / mean;
    return 1.0 / (1.0 + cv);
  }
}
