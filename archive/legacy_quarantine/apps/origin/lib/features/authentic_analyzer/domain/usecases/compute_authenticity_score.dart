import 'package:origin/core/services/database_service.dart';
import 'package:origin/features/authentic_analyzer/data/metrics/revision_pattern_metric.dart';
import 'package:origin/features/authentic_analyzer/data/metrics/rhythm_entropy_metric.dart';
import 'package:origin/features/authentic_analyzer/data/metrics/temporal_consistency_metric.dart';
import 'package:origin/features/authentic_analyzer/data/metrics/vocabulary_richness_metric.dart';
import 'package:origin/features/authentic_analyzer/domain/models/authenticity_result.dart';

/// Use case that computes an [AuthenticityResult] for a given session.
///
/// Gathers keystroke events for the session, runs the 4 metric classes
/// (RhythmEntropy, RevisionPattern, VocabularyRichness, TemporalConsistency),
/// and returns a composite authenticity score.
class ComputeAuthenticityScore {
  /// Execute the authenticity computation for [sessionId].
  ///
  /// Returns an [AuthenticityResult] containing the composite score
  /// and each individual metric.
  Future<AuthenticityResult> execute(String sessionId) async {
    final db = globalDatabaseService;

    // Fetch events and session data
    final events = await db.getEventsForSession(sessionId);
    final session = await db.getSessionById(sessionId);

    // Extract content for vocabulary richness
    final content = session?['content'] as String? ?? '';

    // Build t-deltas from events
    final tdeltas = events
        .map((e) => (e['t_delta'] as num?)?.toDouble() ?? 0)
        .toList();

    // Count backspace events
    int backspaceCount = 0;
    int eventCount = 0;
    for (final event in events) {
      if ((event['is_backspace'] as int?) == 1) {
        backspaceCount++;
      } else {
        eventCount++;
      }
    }

    // Run metrics
    final rhythmEntropy =
        RhythmEntropyMetric.compute(tdeltas);
    final revisionPattern = RevisionPatternMetric.compute(
      eventCount: eventCount,
      backspaceCount: backspaceCount,
    );
    final vocabularyRichness =
        VocabularyRichnessMetric.compute(content);
    final temporalConsistency =
        TemporalConsistencyMetric.compute(tdeltas);

    // Simple average composite score (normalized 0–100 scale)
    final compositeScore = (rhythmEntropy +
                revisionPattern +
                vocabularyRichness +
                temporalConsistency) /
            4.0 *
        100;

    return AuthenticityResult(
      sessionId: sessionId,
      compositeScore: compositeScore,
      rhythmEntropy: rhythmEntropy,
      revisionPatternScore: revisionPattern,
      vocabularyRichness: vocabularyRichness,
      temporalConsistency: temporalConsistency,
    );
  }
}
