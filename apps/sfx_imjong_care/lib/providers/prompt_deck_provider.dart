import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PromptDeckState {
  final List<String> questions;
  final int currentIndex;

  PromptDeckState({
    required this.questions,
    required this.currentIndex,
  });

  String get currentQuestion => questions[currentIndex];

  PromptDeckState copyWith({
    List<String>? questions,
    int? currentIndex,
  }) {
    return PromptDeckState(
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }
}

class PromptDeckNotifier extends StateNotifier<PromptDeckState> {
  PromptDeckNotifier()
      : super(
          PromptDeckState(
            questions: [
              "Q. 사랑하는 이들에게 평소 말하지 못했던, 가슴속 깊이 묻어둔 고마운 기억은 무엇인가요?",
              "Q. 내가 떠난 후, 남겨진 사람들이 나를 기억할 때 떠올려 주었으면 하는 모습이 있나요?",
              "Q. 인생의 마지막 여정에서 가장 아름다웠던 한 순간을 고른다면 언제인가요?",
              "Q. 지금 당장 내일 떠난다면, 가장 미안해서 마음 한구석이 아련해지는 사람은 누구인가요?",
              "Q. 남겨진 소중한 이들에게 남기는 마지막 조언이나 응원의 한마디는 무엇인가요?",
              "Q. 인생을 돌아보며 나 스스로에게 가장 칭찬해주고 싶은 나의 자랑스러운 선택은 무엇인가요?",
              "Q. 나의 소중한 물건이나 유품을 누구에게 어떤 마음으로 전하고 싶나요?"
            ],
            currentIndex: 0,
          ),
        );

  void nextQuestion() {
    state = state.copyWith(
      currentIndex: (state.currentIndex + 1) % state.questions.length,
    );
  }

  void prevQuestion() {
    state = state.copyWith(
      currentIndex: (state.currentIndex - 1 + state.questions.length) % state.questions.length,
    );
  }

  void shuffleQuestions() {
    final shuffled = List<String>.from(state.questions);
    shuffled.shuffle(Random());
    state = state.copyWith(
      questions: shuffled,
      currentIndex: 0,
    );
  }
}

final promptDeckProvider = StateNotifierProvider<PromptDeckNotifier, PromptDeckState>((ref) {
  return PromptDeckNotifier();
});
