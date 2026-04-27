import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sfx_imjong_care/core/theme/card_template.dart';

class CardTemplateState {
  final CardTemplate template;
  final String name;
  final List<String> values;
  final String will;

  const CardTemplateState({
    this.template = CardTemplate.neon,
    this.name = '',
    required this.values,
    this.will = '',
  });

  CardTemplateState copyWith({
    CardTemplate? template,
    String? name,
    List<String>? values,
    String? will,
  }) {
    return CardTemplateState(
      template: template ?? this.template,
      name: name ?? this.name,
      values: values ?? this.values,
      will: will ?? this.will,
    );
  }
}

class CardTemplateController extends StateNotifier<CardTemplateState> {
  CardTemplateController()
      : super(const CardTemplateState(values: ['', '', '']));

  void setTemplate(CardTemplate template) {
    state = state.copyWith(template: template);
  }

  void updateName(String value) {
    state = state.copyWith(name: value);
  }

  void updateValue(int index, String value) {
    final newValues = List<String>.from(state.values);
    if (index >= 0 && index < newValues.length) {
      newValues[index] = value;
    }
    state = state.copyWith(values: newValues);
  }

  void updateWill(String value) {
    state = state.copyWith(will: value);
  }

  void reset() {
    state = const CardTemplateState(values: ['', '', '']);
  }

  bool get isValid =>
      state.name.trim().isNotEmpty &&
      state.values.every((v) => v.trim().isNotEmpty) &&
      state.will.trim().isNotEmpty;
}

final cardTemplateControllerProvider =
    StateNotifierProvider<CardTemplateController, CardTemplateState>((ref) {
  return CardTemplateController();
});
