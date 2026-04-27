/// WillCard entity - represents a user's digital will card
class WillCard {
  final String name;
  final List<String> values;
  final String will;

  const WillCard({
    required this.name,
    required this.values,
    required this.will,
  });

  WillCard copyWith({
    String? name,
    List<String>? values,
    String? will,
  }) {
    return WillCard(
      name: name ?? this.name,
      values: values ?? this.values,
      will: will ?? this.will,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'values': values,
      'will': will,
    };
  }

  factory WillCard.fromMap(Map<String, dynamic> map) {
    return WillCard(
      name: map['name'] as String,
      values: List<String>.from(map['values'] as List),
      will: map['will'] as String,
    );
  }

  @override
  String toString() {
    return 'WillCard(name: $name, values: $values, will: $will)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WillCard &&
        other.name == name &&
        other.values.length == values.length &&
        other.values.asMap().entries.every((e) => e.value == values[e.key]) &&
        other.will == will;
  }

  @override
  int get hashCode => name.hashCode ^ values.hashCode ^ will.hashCode;
}
