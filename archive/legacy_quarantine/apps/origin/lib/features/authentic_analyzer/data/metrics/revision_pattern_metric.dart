/// Revision Pattern Metric: Scoring based on backspace frequency relative
/// to total keystroke events.
///
/// Formula: score = 0.5 + 0.5 * (1.0 - backspaceRatio)
///   where backspaceRatio = backspaceCount / totalEvents
/// Range: [0.0, 1.0] where 1.0 = no backspaces (authentic writing).
class RevisionPatternMetric {
  /// Compute revision pattern score.
  ///
  /// [eventCount] is the number of non-backspace keystroke events.
  /// [backspaceCount] is the number of backspace key presses.
  static double compute({
    required int eventCount,
    required int backspaceCount,
  }) {
    final totalEvents = eventCount + backspaceCount;
    final backspaceRatio =
        totalEvents > 0 ? backspaceCount / totalEvents : 0.0;
    return 0.5 + 0.5 * (1.0 - backspaceRatio);
  }
}
