import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PromptDeckState {
  final List<int> questionIndices;
  final int currentIndex;

  PromptDeckState({
    required this.questionIndices,
    required this.currentIndex,
  });

  int get currentQuestionIndex => questionIndices[currentIndex];

  PromptDeckState copyWith({
    List<int>? questionIndices,
    int? currentIndex,
  }) {
    return PromptDeckState(
      questionIndices: questionIndices ?? this.questionIndices,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }
}

class PromptDeckNotifier extends StateNotifier<PromptDeckState> {
  PromptDeckNotifier()
      : super(
          PromptDeckState(
            // Pre-populated indices for 7 standard questions
            questionIndices: List<int>.generate(7, (index) => index),
            currentIndex: 0,
          ),
        );

  void nextQuestion() {
    state = state.copyWith(
      currentIndex: (state.currentIndex + 1) % state.questionIndices.length,
    );
  }

  void prevQuestion() {
    state = state.copyWith(
      currentIndex: (state.currentIndex - 1 + state.questionIndices.length) % state.questionIndices.length,
    );
  }

  void shuffleQuestions() {
    final shuffled = List<int>.from(state.questionIndices);
    shuffled.shuffle(Random());
    state = state.copyWith(
      questionIndices: shuffled,
      currentIndex: 0,
    );
  }
}

final promptDeckProvider = StateNotifierProvider<PromptDeckNotifier, PromptDeckState>((ref) {
  return PromptDeckNotifier();
});
