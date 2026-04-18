class CheckinData {
  final int energyLevel;
  final String mood;
  final String focusMode;

  const CheckinData({
    required this.energyLevel,
    required this.mood,
    required this.focusMode,
  });

  Map<String, dynamic> toJson() {
    return {
      'energyLevel': energyLevel,
      'mood': mood,
      'focusMode': focusMode,
    };
  }
}
