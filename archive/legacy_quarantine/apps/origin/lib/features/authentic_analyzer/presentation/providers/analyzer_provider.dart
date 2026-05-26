import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origin/features/authentic_analyzer/domain/models/authenticity_result.dart';
import 'package:origin/features/authentic_analyzer/domain/usecases/compute_authenticity_score.dart';

/// State for the authenticity analysis result.
class AnalyzerState {
  final AuthenticityResult? result;
  final String? error;
  final bool isLoading;

  const AnalyzerState({
    this.result,
    this.error,
    this.isLoading = false,
  });

  AnalyzerState copyWith({
    AuthenticityResult? result,
    String? error,
    bool? isLoading,
  }) =>
      AnalyzerState(
        result: result ?? this.result,
        error: error ?? this.error,
        isLoading: isLoading ?? this.isLoading,
      );
}

/// Riverpod notifier that loads and analyzes authenticity data per session.
class AnalyzerNotifier
    extends Notifier<AnalyzerState?> {
  @override
  AnalyzerState? build() => const AnalyzerState();

  /// Load authenticity analysis for [sessionId].
  Future<void> analyzeSession(String sessionId) async {
    state = const AnalyzerState(isLoading: true);

    try {
      final useCase = ComputeAuthenticityScore();
      final result = await useCase.execute(sessionId);
      state = AnalyzerState(result: result);
    } catch (e) {
      state = AnalyzerState(error: e.toString());
    }
  }
}

/// Provider exposing the analyzer state.
final analyzerProvider =
    NotifierProvider<AnalyzerNotifier, AnalyzerState?>(
  () => AnalyzerNotifier(),
);
