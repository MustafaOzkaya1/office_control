enum TaskStatus { todo, inProgress, done }

enum TaskDifficulty { easy, medium, hard, veryHard }

class TaskModel {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final TaskStatus status;
  final TaskDifficulty difficulty;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int? durationMinutes;

  TaskModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.status,
    required this.difficulty,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.durationMinutes,
  });

  String get difficultyLabel {
    switch (difficulty) {
      case TaskDifficulty.easy:
        return 'Kolay';
      case TaskDifficulty.medium:
        return 'Orta';
      case TaskDifficulty.hard:
        return 'Zor';
      case TaskDifficulty.veryHard:
        return 'Çok Zor';
    }
  }

  String get statusLabel {
    switch (status) {
      case TaskStatus.todo:
        return 'To-Do';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.done:
        return 'Done';
    }
  }

  int get difficultyPoints {
    switch (difficulty) {
      case TaskDifficulty.easy:
        return 1;
      case TaskDifficulty.medium:
        return 2;
      case TaskDifficulty.hard:
        return 3;
      case TaskDifficulty.veryHard:
        return 5;
    }
  }

  String get formattedDuration {
    if (durationMinutes == null) return '-';
    final hours = durationMinutes! ~/ 60;
    final mins = durationMinutes! % 60;
    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    return '${mins}m';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'status': status.name,
      'difficulty': difficulty.name,
      'createdAt': createdAt.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'durationMinutes': durationMinutes,
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'],
      status: TaskStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TaskStatus.todo,
      ),
      difficulty: TaskDifficulty.values.firstWhere(
        (e) => e.name == map['difficulty'],
        orElse: () => TaskDifficulty.medium,
      ),
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      startedAt: map['startedAt'] != null
          ? DateTime.tryParse(map['startedAt'])
          : null,
      completedAt: map['completedAt'] != null
          ? DateTime.tryParse(map['completedAt'])
          : null,
      durationMinutes: map['durationMinutes'],
    );
  }

  TaskModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    TaskStatus? status,
    TaskDifficulty? difficulty,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    int? durationMinutes,
  }) {
    return TaskModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      difficulty: difficulty ?? this.difficulty,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
    );
  }
}
