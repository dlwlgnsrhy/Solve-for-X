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
      "energyLevel": energyLevel,
      "mood": mood,
      "focusMode": focusMode,
    };
  }

  factory CheckinData.fromJson(Map<String, dynamic> json) {
    return CheckinData(
      energyLevel: json['energyLevel'] as int,
      mood: json['mood'] as String,
      focusMode: json['focusMode'] as String,
    );
  }
}
