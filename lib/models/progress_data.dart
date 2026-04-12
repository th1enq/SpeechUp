class ProgressData {
  final int fluencyScore;
  final int pronunciationScore;
  final int averageSpeed;
  final double totalMinutes;
  final int sessionsCount;
  final List<int> weeklyScores;

  const ProgressData({
    this.fluencyScore = 0,
    this.pronunciationScore = 0,
    this.averageSpeed = 0,
    this.totalMinutes = 0,
    this.sessionsCount = 0,
    this.weeklyScores = const [],
  });

  factory ProgressData.fromMap(Map<String, dynamic> map) {
    return ProgressData(
      fluencyScore: map['fluencyScore'] ?? 0,
      pronunciationScore: map['pronunciationScore'] ?? 0,
      averageSpeed: map['averageSpeed'] ?? 0,
      totalMinutes: (map['totalMinutes'] ?? 0).toDouble(),
      sessionsCount: map['sessionsCount'] ?? 0,
      weeklyScores: List<int>.from(map['weeklyScores'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fluencyScore': fluencyScore,
      'pronunciationScore': pronunciationScore,
      'averageSpeed': averageSpeed,
      'totalMinutes': totalMinutes,
      'sessionsCount': sessionsCount,
      'weeklyScores': weeklyScores,
    };
  }
}
