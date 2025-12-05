enum NotificationCategory {
  general,
  announcement,
  task,
  meeting,
  urgent,
  reminder,
  system,
}

enum NotificationPriority { low, normal, high, critical }

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final NotificationCategory category;
  final NotificationPriority priority;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final List<String>? targetUserIds; // null = all users
  final bool isRead;
  final Map<String, bool>? readBy; // userId: isRead

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    required this.priority,
    required this.createdBy,
    required this.createdAt,
    this.expiresAt,
    this.targetUserIds,
    this.isRead = false,
    this.readBy,
  });

  String get categoryLabel {
    switch (category) {
      case NotificationCategory.general:
        return 'Genel';
      case NotificationCategory.announcement:
        return 'Duyuru';
      case NotificationCategory.task:
        return 'Görev';
      case NotificationCategory.meeting:
        return 'Toplantı';
      case NotificationCategory.urgent:
        return 'Acil';
      case NotificationCategory.reminder:
        return 'Hatırlatma';
      case NotificationCategory.system:
        return 'Sistem';
    }
  }

  String get categoryIcon {
    switch (category) {
      case NotificationCategory.general:
        return 'info';
      case NotificationCategory.announcement:
        return 'campaign';
      case NotificationCategory.task:
        return 'task';
      case NotificationCategory.meeting:
        return 'groups';
      case NotificationCategory.urgent:
        return 'warning';
      case NotificationCategory.reminder:
        return 'alarm';
      case NotificationCategory.system:
        return 'settings';
    }
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  bool isReadByUser(String userId) {
    if (readBy == null) return false;
    return readBy![userId] ?? false;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'category': category.name,
      'priority': priority.name,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'targetUserIds': targetUserIds,
      'readBy': readBy ?? {},
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      category: NotificationCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => NotificationCategory.general,
      ),
      priority: NotificationPriority.values.firstWhere(
        (e) => e.name == map['priority'],
        orElse: () => NotificationPriority.normal,
      ),
      createdBy: map['createdBy'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      expiresAt: map['expiresAt'] != null
          ? DateTime.tryParse(map['expiresAt'])
          : null,
      targetUserIds: map['targetUserIds'] != null
          ? List<String>.from(map['targetUserIds'])
          : null,
      readBy: map['readBy'] != null
          ? Map<String, bool>.from(map['readBy'])
          : null,
    );
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    NotificationCategory? category,
    NotificationPriority? priority,
    String? createdBy,
    DateTime? createdAt,
    DateTime? expiresAt,
    List<String>? targetUserIds,
    bool? isRead,
    Map<String, bool>? readBy,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      targetUserIds: targetUserIds ?? this.targetUserIds,
      isRead: isRead ?? this.isRead,
      readBy: readBy ?? this.readBy,
    );
  }
}

