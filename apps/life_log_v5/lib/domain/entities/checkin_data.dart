class CheckinData {
  final int energyLevel;
  final String mood;
  final String focusMode;

  CheckinData({
    required this.energyLevel,
    required this.mood,
    required this.focusMode,
  });

  Map<<StringString, dynamic> toJson() {
    return {
      "energyLevel": energyLevel,
      "mood": mood,
      "focusMode": focusMode,
    };
  }
}
