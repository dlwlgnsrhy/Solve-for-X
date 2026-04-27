import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sfx_imjong_care/features/will_input/data/repositories/will_card_storage.dart';
import 'package:sfx_imjong_care/features/will_input/domain/entities/will_card.dart';

class WillFormState {
  final String name;
  final List<String> values;
  final String will;

  const WillFormState({
    this.name = '',
    required this.values,
    this.will = '',
  });

  WillFormState copyWith({
    String? name,
    List<String>? values,
    String? will,
  }) {
    return WillFormState(
      name: name ?? this.name,
      values: values ?? this.values,
      will: will ?? this.will,
    );
  }
}

class WillFormController extends StateNotifier<WillFormState> {
  final WillCardStorage _storage;

  WillFormController({WillCardStorage? storage})
      : _storage = storage ?? WillCardStorage(),
        super(const WillFormState(values: ['', '', ''])) {
    _loadSavedData();
  }

  /// Load saved data from local storage on initialization.
  Future<void> _loadSavedData() async {
    final saved = await _storage.loadCard();
    if (saved != null) {
      state = WillFormState(
        name: saved.name,
        values: saved.values,
        will: saved.will,
      );
    }
  }

  /// Auto-save to local storage after state changes.
  Future<void> _autoSave() async {
    if (isValid) {
      final card = WillCard(
        name: state.name.trim(),
        values: state.values.map((v) => v.trim()).toList(),
        will: state.will.trim(),
      );
      await _storage.saveCard(card);
    }
  }

  void updateName(String value) {
    state = state.copyWith(name: value);
    _autoSave();
  }

  void updateValue(int index, String value) {
    final newValues = List<String>.from(state.values);
    if (index >= 0 && index < newValues.length) {
      newValues[index] = value;
    }
    state = state.copyWith(values: newValues);
    _autoSave();
  }

  void updateWill(String value) {
    state = state.copyWith(will: value);
    _autoSave();
  }

  void reset() {
    state = const WillFormState(values: ['', '', '']);
    _storage.clear();
  }

  bool get isValid =>
      state.name.trim().isNotEmpty &&
      state.values.every((v) => v.trim().isNotEmpty) &&
      state.will.trim().isNotEmpty;
}

final willFormControllerProvider =
    StateNotifierProvider<WillFormController, WillFormState>((ref) {
  return WillFormController();
});
