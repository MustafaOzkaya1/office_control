enum RequestStatus { pending, approved, rejected }

class AccessRequestModel {
  final String id;
  final String email;
  final String password; // User sets their own password
  final String firstName;
  final String lastName;
  final String position;
  final String phone;
  final String reason;
  final RequestStatus status;
  final DateTime createdAt;
  final DateTime? processedAt;
  final String? processedBy;
  final String? rejectionReason;

  AccessRequestModel({
    required this.id,
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.position,
    required this.phone,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.processedAt,
    this.processedBy,
    this.rejectionReason,
  });

  String get fullName => '$firstName $lastName';

  bool get isPending => status == RequestStatus.pending;
  bool get isApproved => status == RequestStatus.approved;
  bool get isRejected => status == RequestStatus.rejected;

  String get statusLabel {
    switch (status) {
      case RequestStatus.pending:
        return 'Beklemede';
      case RequestStatus.approved:
        return 'Onaylandı';
      case RequestStatus.rejected:
        return 'Reddedildi';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'password': password, // Store encrypted or handle securely
      'firstName': firstName,
      'lastName': lastName,
      'position': position,
      'phone': phone,
      'reason': reason,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'processedAt': processedAt?.toIso8601String(),
      'processedBy': processedBy,
      'rejectionReason': rejectionReason,
    };
  }

  factory AccessRequestModel.fromMap(Map<String, dynamic> map) {
    return AccessRequestModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      position: map['position'] ?? '',
      phone: map['phone'] ?? '',
      reason: map['reason'] ?? '',
      status: RequestStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => RequestStatus.pending,
      ),
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      processedAt: map['processedAt'] != null
          ? DateTime.tryParse(map['processedAt'])
          : null,
      processedBy: map['processedBy'],
      rejectionReason: map['rejectionReason'],
    );
  }

  AccessRequestModel copyWith({
    String? id,
    String? email,
    String? password,
    String? firstName,
    String? lastName,
    String? position,
    String? phone,
    String? reason,
    RequestStatus? status,
    DateTime? createdAt,
    DateTime? processedAt,
    String? processedBy,
    String? rejectionReason,
  }) {
    return AccessRequestModel(
      id: id ?? this.id,
      email: email ?? this.email,
      password: password ?? this.password,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      position: position ?? this.position,
      phone: phone ?? this.phone,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      processedAt: processedAt ?? this.processedAt,
      processedBy: processedBy ?? this.processedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}
