class AIPerformance {
  final double dailyScore;
  final int generalScoreXp;
  final String careerLevel;
  final String speedLabel;
  final String dailyMood;
  final List<String> actionItems;
  final String? clusterRole; // 🧘 Derin Odak (Teknik/Yazılım) gibi

  AIPerformance({
    required this.dailyScore,
    required this.generalScoreXp,
    required this.careerLevel,
    required this.speedLabel,
    required this.dailyMood,
    required this.actionItems,
    this.clusterRole,
  });

  Map<String, dynamic> toMap() {
    return {
      'daily_score': dailyScore,
      'general_score_xp': generalScoreXp,
      'career_level': careerLevel,
      'speed_label': speedLabel,
      'daily_mood': dailyMood,
      'action_items': actionItems,
      if (clusterRole != null) 'cluster_role': clusterRole,
    };
  }

  factory AIPerformance.fromMap(Map<String, dynamic> map) {
    return AIPerformance(
      dailyScore: (map['daily_score'] as num?)?.toDouble() ?? 0.0,
      generalScoreXp: (map['general_score_xp'] as num?)?.toInt() ?? 0,
      careerLevel: map['career_level'] as String? ?? 'Başlangıç',
      speedLabel: map['speed_label'] as String? ?? 'Normal',
      dailyMood: map['daily_mood'] as String? ?? 'Normal',
      actionItems:
          (map['action_items'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      clusterRole: map['cluster_role'] as String?,
    );
  }

  AIPerformance copyWith({
    double? dailyScore,
    int? generalScoreXp,
    String? careerLevel,
    String? speedLabel,
    String? dailyMood,
    List<String>? actionItems,
    String? clusterRole,
  }) {
    return AIPerformance(
      dailyScore: dailyScore ?? this.dailyScore,
      generalScoreXp: generalScoreXp ?? this.generalScoreXp,
      careerLevel: careerLevel ?? this.careerLevel,
      speedLabel: speedLabel ?? this.speedLabel,
      dailyMood: dailyMood ?? this.dailyMood,
      actionItems: actionItems ?? this.actionItems,
      clusterRole: clusterRole ?? this.clusterRole,
    );
  }
}
