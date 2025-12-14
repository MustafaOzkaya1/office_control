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
  final String? humanTime; // Örn: "4 saat 30 dk" veya "9sa 49dk"
  final int? predictedMinutes; // Örn: 589
  final String? category; // Örn: "Architecture & DevOps"
  final int? processedAt; // Timestamp
  final String? status;
  final String? error;

  AIPredictResponse({
    this.humanTime,
    this.predictedMinutes,
    this.category,
    this.processedAt,
    this.status,
    this.error,
  });

  Map<String, dynamic> toMap() {
    return {
      'human_time': humanTime,
      'predicted_minutes': predictedMinutes,
      'category': category,
      'processed_at': processedAt,
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
      predictedMinutes: (map['predicted_minutes'] as num?)?.toInt(),
      category: map['category'] as String?,
      processedAt: (map['processed_at'] as num?)?.toInt(),
      status: map['status'] as String?,
      error: map['error'] as String?,
    );
  }

  bool get hasData =>
      humanTime != null ||
      predictedMinutes != null ||
      category != null;
  bool get hasError => error != null;
}

