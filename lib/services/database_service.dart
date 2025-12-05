import 'package:firebase_database/firebase_database.dart';
import 'package:office_control/models/user_model.dart';
import 'package:office_control/models/task_model.dart';
import 'package:office_control/models/access_request_model.dart';
import 'package:office_control/models/attendance_model.dart';
import 'package:office_control/models/office_location_model.dart';
import 'package:office_control/models/notification_model.dart';
import 'package:intl/intl.dart';

class DatabaseService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  DatabaseReference get _usersRef => _db.ref('users');
  DatabaseReference get _requestsRef => _db.ref('access_requests');
  DatabaseReference get _officeRef => _db.ref('office');
  DatabaseReference get _notificationsRef => _db.ref('notifications');

  // ==================== USER OPERATIONS ====================

  Future<void> createUser(UserModel user) async {
    await _usersRef.child(user.uid).set(user.toMap());
  }

  Future<UserModel?> getUser(String uid) async {
    final snapshot = await _usersRef.child(uid).get();
    if (!snapshot.exists || snapshot.value == null) return null;
    
    final data = Map<String, dynamic>.from(snapshot.value as Map);
    
    if (data['role'] == UserRole.admin.name) {
      return Admin.fromMap(data);
    }
    return Employee.fromMap(data);
  }

  Future<void> updateUser(String uid, Map<String, dynamic> updates) async {
    await _usersRef.child(uid).update(updates);
  }

  Stream<UserModel?> userStream(String uid) {
    return _usersRef.child(uid).onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) return null;
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      if (data['role'] == UserRole.admin.name) {
        return Admin.fromMap(data);
      }
      return Employee.fromMap(data);
    });
  }

  Future<List<UserModel>> getAllUsers() async {
    final snapshot = await _usersRef.get();
    if (!snapshot.exists || snapshot.value == null) return [];
    
    final data = Map<String, dynamic>.from(snapshot.value as Map);
    return data.values.map((v) {
      final userData = Map<String, dynamic>.from(v);
      if (userData['role'] == UserRole.admin.name) {
        return Admin.fromMap(userData);
      }
      return Employee.fromMap(userData);
    }).toList();
  }

  // ==================== ACCESS REQUEST OPERATIONS ====================

  Future<void> createAccessRequest(AccessRequestModel request) async {
    await _requestsRef.child(request.id).set(request.toMap());
  }

  Future<AccessRequestModel?> getAccessRequest(String id) async {
    final snapshot = await _requestsRef.child(id).get();
    if (!snapshot.exists || snapshot.value == null) return null;
    return AccessRequestModel.fromMap(
      Map<String, dynamic>.from(snapshot.value as Map),
    );
  }

  Stream<List<AccessRequestModel>> pendingRequestsStream() {
    return _requestsRef
        .orderByChild('status')
        .equalTo('pending')
        .onValue
        .map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) return [];
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      return data.values
          .map((v) => AccessRequestModel.fromMap(Map<String, dynamic>.from(v)))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  Future<List<AccessRequestModel>> getPendingRequests() async {
    final snapshot = await _requestsRef
        .orderByChild('status')
        .equalTo('pending')
        .get();
    
    if (!snapshot.exists || snapshot.value == null) return [];
    
    final data = Map<String, dynamic>.from(snapshot.value as Map);
    return data.values
        .map((v) => AccessRequestModel.fromMap(Map<String, dynamic>.from(v)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> approveRequest(String requestId, String adminUid) async {
    await _requestsRef.child(requestId).update({
      'status': RequestStatus.approved.name,
      'processedAt': DateTime.now().toIso8601String(),
      'processedBy': adminUid,
    });
  }

  Future<void> rejectRequest(String requestId, String adminUid, String reason) async {
    await _requestsRef.child(requestId).update({
      'status': RequestStatus.rejected.name,
      'processedAt': DateTime.now().toIso8601String(),
      'processedBy': adminUid,
      'rejectionReason': reason,
    });
  }

  Future<void> clearRequestPassword(String requestId) async {
    // Clear password from request for security after approval
    await _requestsRef.child(requestId).child('password').remove();
  }

  // ==================== TASK OPERATIONS ====================

  DatabaseReference _userTasksRef(String uid) => _usersRef.child(uid).child('tasks');

  Future<void> createTask(TaskModel task) async {
    await _userTasksRef(task.userId).child(task.id).set(task.toMap());
  }

  Future<void> updateTask(TaskModel task) async {
    await _userTasksRef(task.userId).child(task.id).update(task.toMap());
  }

  Future<void> deleteTask(String userId, String taskId) async {
    await _userTasksRef(userId).child(taskId).remove();
  }

  Future<TaskModel?> getTask(String userId, String taskId) async {
    final snapshot = await _userTasksRef(userId).child(taskId).get();
    if (!snapshot.exists || snapshot.value == null) return null;
    return TaskModel.fromMap(Map<String, dynamic>.from(snapshot.value as Map));
  }

  Stream<List<TaskModel>> userTasksStream(String userId) {
    return _userTasksRef(userId).onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) return [];
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      return data.values
          .map((v) => TaskModel.fromMap(Map<String, dynamic>.from(v)))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  Future<void> startTask(String userId, String taskId) async {
    await _userTasksRef(userId).child(taskId).update({
      'status': TaskStatus.inProgress.name,
      'startedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> completeTask(String userId, String taskId) async {
    final task = await getTask(userId, taskId);
    if (task == null) return;

    int? durationMinutes;
    if (task.startedAt != null) {
      durationMinutes = DateTime.now().difference(task.startedAt!).inMinutes;
    }

    await _userTasksRef(userId).child(taskId).update({
      'status': TaskStatus.done.name,
      'completedAt': DateTime.now().toIso8601String(),
      'durationMinutes': durationMinutes,
    });
  }

  // ==================== ATTENDANCE OPERATIONS ====================

  String _getTodayDateKey() => DateFormat('yyyy-MM-dd').format(DateTime.now());

  DatabaseReference _userAttendanceRef(String uid, String date) =>
      _usersRef.child(uid).child('attendance').child(date);

  Future<void> recordAttendance(AttendanceRecord record) async {
    final dateKey = DateFormat('yyyy-MM-dd').format(record.timestamp);
    await _userAttendanceRef(record.userId, dateKey)
        .child('records')
        .child(record.id)
        .set(record.toMap());
    
    // Update total minutes
    final attendance = await getDailyAttendance(record.userId, dateKey);
    if (attendance != null) {
      final totalMinutes = attendance.calculateTotalMinutes();
      await _userAttendanceRef(record.userId, dateKey).update({
        'totalMinutesWorked': totalMinutes,
        'date': dateKey,
        'userId': record.userId,
      });
    }
  }

  Future<DailyAttendance?> getDailyAttendance(String userId, String date) async {
    final snapshot = await _userAttendanceRef(userId, date).get();
    if (!snapshot.exists || snapshot.value == null) return null;
    
    final data = Map<String, dynamic>.from(snapshot.value as Map);
    return DailyAttendance.fromMap(data);
  }

  Future<DailyAttendance?> getTodayAttendance(String userId) async {
    return getDailyAttendance(userId, _getTodayDateKey());
  }

  Stream<DailyAttendance?> todayAttendanceStream(String userId) {
    return _userAttendanceRef(userId, _getTodayDateKey()).onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) return null;
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      return DailyAttendance.fromMap(data);
    });
  }

  Future<List<DailyAttendance>> getAttendanceHistory(String userId, {int days = 30}) async {
    final attendances = <DailyAttendance>[];
    final now = DateTime.now();
    
    for (int i = 0; i < days; i++) {
      final date = DateFormat('yyyy-MM-dd').format(now.subtract(Duration(days: i)));
      final attendance = await getDailyAttendance(userId, date);
      if (attendance != null) {
        attendances.add(attendance);
      }
    }
    
    return attendances;
  }

  // ==================== OFFICE LOCATION OPERATIONS ====================

  Future<OfficeLocation?> getOfficeLocation() async {
    final snapshot = await _officeRef.child('location').get();
    if (!snapshot.exists || snapshot.value == null) return null;
    return OfficeLocation.fromMap(
      Map<String, dynamic>.from(snapshot.value as Map),
    );
  }

  Stream<OfficeLocation?> officeLocationStream() {
    return _officeRef.child('location').onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) return null;
      return OfficeLocation.fromMap(
        Map<String, dynamic>.from(event.snapshot.value as Map),
      );
    });
  }

  Future<void> updateOfficeLocation(OfficeLocation location) async {
    await _officeRef.child('location').set(location.toMap());
  }

  // ==================== NOTIFICATION OPERATIONS ====================

  Future<void> createNotification(NotificationModel notification) async {
    await _notificationsRef.child(notification.id).set(notification.toMap());
  }

  Future<void> deleteNotification(String notificationId) async {
    await _notificationsRef.child(notificationId).remove();
  }

  Future<NotificationModel?> getNotification(String notificationId) async {
    final snapshot = await _notificationsRef.child(notificationId).get();
    if (!snapshot.exists || snapshot.value == null) return null;
    return NotificationModel.fromMap(
      Map<String, dynamic>.from(snapshot.value as Map),
    );
  }

  Stream<List<NotificationModel>> notificationsStream({String? userId}) {
    return _notificationsRef.onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) return [];
      
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      final notifications = data.values
          .map((v) => NotificationModel.fromMap(Map<String, dynamic>.from(v)))
          .where((n) {
            // Filter out expired notifications
            if (n.isExpired) return false;
            // If targetUserIds is null, show to all users
            if (n.targetUserIds == null) return true;
            // If userId provided, check if user is in target list
            if (userId != null) {
              return n.targetUserIds!.contains(userId);
            }
            return true;
          })
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return notifications;
    });
  }

  Future<List<NotificationModel>> getNotifications({String? userId}) async {
    final snapshot = await _notificationsRef.get();
    if (!snapshot.exists || snapshot.value == null) return [];

    final data = Map<String, dynamic>.from(snapshot.value as Map);
    return data.values
        .map((v) => NotificationModel.fromMap(Map<String, dynamic>.from(v)))
        .where((n) {
          if (n.isExpired) return false;
          if (n.targetUserIds == null) return true;
          if (userId != null) {
            return n.targetUserIds!.contains(userId);
          }
          return true;
        })
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> markNotificationAsRead(String notificationId, String userId) async {
    await _notificationsRef.child(notificationId).child('readBy').child(userId).set(true);
  }

  Future<void> markAllNotificationsAsRead(String userId) async {
    final notifications = await getNotifications(userId: userId);
    for (final notification in notifications) {
      await markNotificationAsRead(notification.id, userId);
    }
  }

  Future<int> getUnreadNotificationCount(String userId) async {
    final notifications = await getNotifications(userId: userId);
    return notifications.where((n) => !n.isReadByUser(userId)).length;
  }

  Stream<int> unreadNotificationCountStream(String userId) {
    return notificationsStream(userId: userId).map((notifications) {
      return notifications.where((n) => !n.isReadByUser(userId)).length;
    });
  }
}

