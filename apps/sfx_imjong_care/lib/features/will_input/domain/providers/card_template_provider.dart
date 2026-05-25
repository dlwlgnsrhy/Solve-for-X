import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sfx_imjong_care/core/theme/card_template.dart';

class CardTemplateState {
  final CardTemplate template;

  const CardTemplateState({
    this.template = CardTemplate.neon,
  });

  CardTemplateState copyWith({
    CardTemplate? template,
  }) {
    return CardTemplateState(
      template: template ?? this.template,
    );
  }
}

class CardTemplateController extends StateNotifier<CardTemplateState> {
  CardTemplateController()
      : super(const CardTemplateState());

  void setTemplate(CardTemplate template) {
    state = state.copyWith(template: template);
  }
}

final cardTemplateControllerProvider =
    StateNotifierProvider<CardTemplateController, CardTemplateState>((ref) {
  return CardTemplateController();
});
