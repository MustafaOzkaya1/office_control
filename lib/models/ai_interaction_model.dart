class AIPredictRequest {
  final String description;
  final String difficulty;
  final String status; // 'pending', 'processing', 'completed'
  final int? timestamp;

  AIPredictRequest({
    required this.description,
    required this.difficulty,
    required this.status,
    this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'difficulty': difficulty,
      'status': status,
      'timestamp': timestamp,
    };
  }

  factory AIPredictRequest.fromMap(Map<String, dynamic> map) {
    return AIPredictRequest(
      description: map['description'] as String? ?? '',
      difficulty: map['difficulty'] as String? ?? 'medium',
      status: map['status'] as String? ?? 'pending',
      timestamp: (map['timestamp'] as num?)?.toInt(),
    );
  }
}

class AIPredictResponse {
  final String? humanTime; // Örn: "4 saat 30 dk"
  final int? estimatedMinutes;
  final String? status;
  final String? error;

  AIPredictResponse({
    this.humanTime,
    this.estimatedMinutes,
    this.status,
    this.error,
  });

  Map<String, dynamic> toMap() {
    return {
      'human_time': humanTime,
      'estimated_minutes': estimatedMinutes,
      'status': status,
      'error': error,
    };
  }

  factory AIPredictResponse.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return AIPredictResponse();
    }
    return AIPredictResponse(
      humanTime: map['human_time'] as String?,
      estimatedMinutes: (map['estimated_minutes'] as num?)?.toInt(),
      status: map['status'] as String?,
      error: map['error'] as String?,
    );
  }

  bool get hasData => humanTime != null || estimatedMinutes != null;
  bool get hasError => error != null;
}

