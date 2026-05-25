class SleepData {
  final int score;
  final String duration;

  SleepData({required this.score, required this.duration});

  Map<String, dynamic> toJson() => {
    'score': score,
    'duration': duration,
  };
}
