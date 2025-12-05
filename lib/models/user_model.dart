enum UserRole { admin, employee, guest }

class UserModel {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final String position;
  final String phone;
  final UserRole role;
  final DateTime createdAt;
  final bool isApproved;

  UserModel({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.position,
    required this.phone,
    required this.role,
    required this.createdAt,
    this.isApproved = false,
  });

  String get fullName => '$firstName $lastName';

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'position': position,
      'phone': phone,
      'role': role.name,
      'createdAt': createdAt.toIso8601String(),
      'isApproved': isApproved,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      position: map['position'] ?? '',
      phone: map['phone'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => UserRole.employee,
      ),
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      isApproved: map['isApproved'] ?? false,
    );
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? firstName,
    String? lastName,
    String? position,
    String? phone,
    UserRole? role,
    DateTime? createdAt,
    bool? isApproved,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      position: position ?? this.position,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      isApproved: isApproved ?? this.isApproved,
    );
  }
}

class Employee extends UserModel {
  Employee({
    required super.uid,
    required super.email,
    required super.firstName,
    required super.lastName,
    required super.position,
    required super.phone,
    required super.createdAt,
    super.isApproved,
  }) : super(role: UserRole.employee);

  factory Employee.fromMap(Map<String, dynamic> map) {
    return Employee(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      position: map['position'] ?? '',
      phone: map['phone'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      isApproved: map['isApproved'] ?? false,
    );
  }
}

class Admin extends UserModel {
  final List<String> permissions;

  Admin({
    required super.uid,
    required super.email,
    required super.firstName,
    required super.lastName,
    required super.position,
    required super.phone,
    required super.createdAt,
    this.permissions = const ['all'],
    super.isApproved = true,
  }) : super(role: UserRole.admin);

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map['permissions'] = permissions;
    return map;
  }

  factory Admin.fromMap(Map<String, dynamic> map) {
    return Admin(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      position: map['position'] ?? '',
      phone: map['phone'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      permissions: List<String>.from(map['permissions'] ?? ['all']),
      isApproved: map['isApproved'] ?? true,
    );
  }
}
