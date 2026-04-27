import 'package:sfx_imjong_care/features/will_input/domain/entities/will_card.dart';

/// Data model for WillCard, implementing persistence serialization
class WillCardModel extends WillCard {
  const WillCardModel({
    required super.name,
    required super.values,
    required super.will,
  });

  factory WillCardModel.fromEntity(WillCard entity) {
    return WillCardModel(
      name: entity.name,
      values: entity.values,
      will: entity.will,
    );
  }

  WillCard toEntity() {
    return WillCard(
      name: name,
      values: values,
      will: will,
    );
  }

  @override
  String toString() {
    return 'WillCardModel(name: $name, values: $values, will: $will)';
  }
}
