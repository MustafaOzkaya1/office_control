import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:office_control/models/user_model.dart';
import 'package:office_control/models/task_model.dart';
import 'package:office_control/models/access_request_model.dart';
import 'package:office_control/models/attendance_model.dart';
import 'package:office_control/models/office_location_model.dart';
import 'package:office_control/models/notification_model.dart';
import 'package:office_control/models/ai_performance_model.dart';
import 'package:office_control/models/ai_interaction_model.dart';
import 'package:office_control/models/company_insights_model.dart';
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
    return _requestsRef.orderByChild('status').equalTo('pending').onValue.map((
      event,
    ) {
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

  Future<void> rejectRequest(
    String requestId,
    String adminUid,
    String reason,
  ) async {
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

  DatabaseReference _userTasksRef(String uid) =>
      _usersRef.child(uid).child('tasks');

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
    debugPrint('🎯 completeTask çağrıldı: userId=$userId, taskId=$taskId');

    // ÖNEMLİ: Görevi önce tamamlayanın path'inden dene, bulamazsan tüm kullanıcılarda ara
    // Admin başka birinin görevini tamamlayabilir, o yüzden görev admin'in path'inde olmayabilir
    TaskModel? task = await getTask(userId, taskId);

    // Eğer bulunamadıysa, tüm kullanıcıların tasks path'lerinde ara
    if (task == null) {
      debugPrint(
        '⚠️ Görev $userId path\'inde bulunamadı, tüm kullanıcılarda aranıyor...',
      );
      final allUsersSnapshot = await _usersRef.get();
      if (allUsersSnapshot.exists && allUsersSnapshot.value != null) {
        final usersData = Map<String, dynamic>.from(
          allUsersSnapshot.value as Map,
        );
        for (final userEntry in usersData.entries) {
          final userTasksRef = _usersRef
              .child(userEntry.key)
              .child('tasks')
              .child(taskId);
          final taskSnapshot = await userTasksRef.get();
          if (taskSnapshot.exists && taskSnapshot.value != null) {
            task = TaskModel.fromMap(
              Map<String, dynamic>.from(taskSnapshot.value as Map),
            );
            debugPrint('✅ Görev bulundu: users/${userEntry.key}/tasks/$taskId');
            break;
          }
        }
      }
    }

    if (task == null) {
      debugPrint(
        '❌ Task bulunamadı: $taskId (hiçbir kullanıcının path\'inde yok)',
      );
      return;
    }

    // CRITICAL: AI performans analizi görevin SAHİBİ için yapılmalı (task.userId)
    // Admin görev tamamlayabilir ama analiz employee için yapılır
    final taskOwnerId = task.userId;
    debugPrint(
      '📋 Görev bilgisi: Başlık=${task.title}, Sahibi=$taskOwnerId, Tamamlayan=$userId',
    );

    int? durationMinutes;
    if (task.startedAt != null) {
      durationMinutes = DateTime.now().difference(task.startedAt!).inMinutes;
    }

    final completedAt = DateTime.now();
    debugPrint(
      '✅ Görev tamamlandı: ${task.title}, Süre: $durationMinutes dakika',
    );

    // Update task status - görevin sahibinin path'inde güncelle
    try {
      final updateData = {
        'status': TaskStatus.done.name,
        'completedAt': completedAt.toIso8601String(),
        if (durationMinutes != null) 'durationMinutes': durationMinutes,
      };
      await _userTasksRef(taskOwnerId).child(taskId).update(updateData);
      debugPrint(
        '✅ Görev durumu güncellendi: users/$taskOwnerId/tasks/$taskId',
      );
      debugPrint('   Update data: $updateData');
      debugPrint('   Status: ${TaskStatus.done.name}');

      // Verify: Görev durumunu kontrol et
      final verifySnapshot = await _userTasksRef(
        taskOwnerId,
      ).child(taskId).child('status').get();
      debugPrint(
        '   ✅ Doğrulama: Firebase\'deki status = ${verifySnapshot.value}',
      );
    } catch (e) {
      debugPrint('❌ Görev durumu güncellenirken hata: $e');
      debugPrint('   Stack trace: ${StackTrace.current}');
    }

    // Trigger AI performance update - GÖREVİN SAHİBİ için
    // Path: users/{taskOwnerId}/task_completions/{taskId}
    try {
      final taskCompletionData = {
        'taskId': taskId,
        'title': task.title,
        'description': task.description ?? '',
        'difficulty': task.difficulty.name,
        'difficultyPoints': task.difficultyPoints,
        'durationMinutes': durationMinutes,
        'completedAt': completedAt.toIso8601String(),
        'userId': taskOwnerId, // GÖREVİN SAHİBİ
        'completedBy': userId, // TAMAMLAYAN (admin olabilir)
        'priority': 'high',
        'expectedUpdateTime': '5-10 seconds',
        'timestamp': ServerValue.timestamp,
      };

      await _usersRef
          .child(taskOwnerId) // GÖREVİN SAHİBİ
          .child('task_completions')
          .child(taskId)
          .set(taskCompletionData);
      debugPrint(
        '✅ task_completions yazıldı: users/$taskOwnerId/task_completions/$taskId',
      );
      debugPrint('   Görev sahibi: $taskOwnerId, Tamamlayan: $userId');
      debugPrint('   Data: $taskCompletionData');
    } catch (e) {
      debugPrint('❌ task_completions yazılırken hata: $e');
    }

    // Also set a trigger flag for immediate Python processing - GÖREVİN SAHİBİ için
    // Path: users/{taskOwnerId}/ai_performance/needs_update
    try {
      final needsUpdateData = {
        'triggered': true,
        'lastTaskCompleted': completedAt.toIso8601String(),
        'taskId': taskId,
        'difficultyPoints': task.difficultyPoints,
        'userId': taskOwnerId, // GÖREVİN SAHİBİ
        'completedBy': userId, // TAMAMLAYAN (admin olabilir)
        'priority': 'high',
        'expectedUpdateTime': '5-10 seconds',
        'timestamp': ServerValue.timestamp,
      };

      await _usersRef
          .child(taskOwnerId) // GÖREVİN SAHİBİ
          .child('ai_performance')
          .child('needs_update')
          .set(needsUpdateData);
      debugPrint(
        '✅ needs_update yazıldı: users/$taskOwnerId/ai_performance/needs_update',
      );
      debugPrint('   Görev sahibi: $taskOwnerId, Tamamlayan: $userId');
      debugPrint('   Data: $needsUpdateData');
      debugPrint('   ⚠️ PYTHON BACKEND ŞİMDİ ŞUNU YAPMALI:');
      debugPrint(
        '      1. users/$taskOwnerId/task_completions/* path\'indeki TÜM görevleri oku',
      );
      debugPrint(
        '      2. Bugünkü (${DateFormat('yyyy-MM-dd').format(completedAt)}) görevleri filtrele',
      );
      debugPrint(
        '      3. Tüm görevlerin difficultyPoints toplamını hesapla (XP)',
      );
      debugPrint('      4. Günlük skor, seviye, hız, ruh hali hesapla');
      debugPrint('      5. users/$taskOwnerId/ai_performance path\'ine yaz:');
      debugPrint('         - daily_score: [hesaplanan skor]');
      debugPrint('         - general_score_xp: [toplam XP]');
      debugPrint('         - career_level: [seviye]');
      debugPrint('         - speed_label: [hız durumu]');
      debugPrint('         - daily_mood: [ruh hali]');
      debugPrint('         - action_items: [öneriler listesi]');
    } catch (e) {
      debugPrint('❌ needs_update yazılırken hata: $e');
    }

    // Set XP rate configuration: 1 XP per minute - GÖREVİN SAHİBİ için
    try {
      await _usersRef
          .child(taskOwnerId) // GÖREVİN SAHİBİ
          .child('ai_performance')
          .child('xp_config')
          .set({
            'xp_per_minute': 1,
            'updated_at': completedAt.toIso8601String(),
          });
      debugPrint(
        '✅ xp_config yazıldı: users/$taskOwnerId/ai_performance/xp_config',
      );
    } catch (e) {
      debugPrint('❌ xp_config yazılırken hata: $e');
    }

    debugPrint(
      '🎉 completeTask tamamlandı - Flutter tarafında AI Performance güncellenecek',
    );

    // Flutter tarafında hemen AI Performance'ı hesapla ve güncelle
    _updateAIPerformanceAfterTaskCompletion(taskOwnerId);
  }

  /// Görev tamamlandıktan sonra AI Performance'ı güncelle
  Future<void> _updateAIPerformanceAfterTaskCompletion(String uid) async {
    try {
      // Kısa bir gecikme ekle (Firebase yazma işleminin tamamlanması için)
      await Future.delayed(const Duration(seconds: 1));

      // AI Performance'ı hesapla ve Firebase'e yaz
      final performance = await _calculateAIPerformanceFromCompletions(uid);
      if (performance != null) {
        await _writeAIPerformanceToFirebase(uid, performance);
        debugPrint('✅ Görev tamamlandıktan sonra AI Performance güncellendi');
      }
    } catch (e) {
      debugPrint('❌ AI Performance güncelleme hatası: $e');
    }
  }

  // ==================== ATTENDANCE OPERATIONS ====================

  String _getTodayDateKey() => DateFormat('yyyy-MM-dd').format(DateTime.now());

  DatabaseReference _userAttendanceRef(String uid, String date) =>
      _usersRef.child(uid).child('attendance').child(date);

  Future<void> recordAttendance(AttendanceRecord record) async {
    final dateKey = DateFormat('yyyy-MM-dd').format(record.timestamp);
    await _userAttendanceRef(
      record.userId,
      dateKey,
    ).child('records').child(record.id).set(record.toMap());

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

    // Trigger AI performance update for attendance changes
    // Especially important for exit (çıkış) to finalize daily score
    try {
      final needsUpdateData = {
        'triggered': true,
        'attendanceType': record.type.name, // 'entry' or 'exit'
        'attendanceTimestamp': record.timestamp.toIso8601String(),
        'userId': record.userId,
        'priority': record.type == AttendanceType.exit ? 'high' : 'normal',
        'expectedUpdateTime': record.type == AttendanceType.exit
            ? '5-10 seconds'
            : '30-60 seconds',
        'timestamp': ServerValue.timestamp,
      };

      await _usersRef
          .child(record.userId)
          .child('ai_performance')
          .child('needs_update')
          .set(needsUpdateData);
      debugPrint(
        '✅ Attendance needs_update yazıldı: users/${record.userId}/ai_performance/needs_update',
      );
      debugPrint('   Type: ${record.type.name}, Data: $needsUpdateData');
    } catch (e) {
      debugPrint('❌ Attendance needs_update yazılırken hata: $e');
    }

    // If it's an exit, also update XP config to ensure daily score is finalized
    if (record.type == AttendanceType.exit) {
      try {
        await _usersRef
            .child(record.userId)
            .child('ai_performance')
            .child('xp_config')
            .set({
              'xp_per_minute': 1,
              'updated_at': record.timestamp.toIso8601String(),
              'finalize_daily_score': true, // Signal to finalize daily score
            });
        debugPrint(
          '✅ Exit xp_config yazıldı: users/${record.userId}/ai_performance/xp_config',
        );
      } catch (e) {
        debugPrint('❌ Exit xp_config yazılırken hata: $e');
      }
    }
  }

  Future<DailyAttendance?> getDailyAttendance(
    String userId,
    String date,
  ) async {
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

  Future<List<DailyAttendance>> getAttendanceHistory(
    String userId, {
    int days = 30,
  }) async {
    final attendances = <DailyAttendance>[];
    final now = DateTime.now();

    for (int i = 0; i < days; i++) {
      final date = DateFormat(
        'yyyy-MM-dd',
      ).format(now.subtract(Duration(days: i)));
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
    try {
      final locationMap = location.toMap();
      // Debug: Kaydedilecek veriyi kontrol et
      print('📍 Office location kaydediliyor:');
      print('   ID: ${location.id}');
      print('   Name: ${location.name}');
      print('   Latitude: ${location.latitude}');
      print('   Longitude: ${location.longitude}');
      print('   Radius: ${location.radiusMeters}m');

      await _officeRef.child('location').set(locationMap);

      // Kayıt sonrası kontrol
      final saved = await getOfficeLocation();
      if (saved != null) {
        print('✅ Office location başarıyla kaydedildi');
        print('   Kaydedilen Latitude: ${saved.latitude}');
        print('   Kaydedilen Longitude: ${saved.longitude}');
      } else {
        print('⚠️ Office location kaydedildi ama okunamadı');
      }
    } catch (e, stackTrace) {
      print('❌ Office location kaydetme hatası: $e');
      print('Stack trace: $stackTrace');
      rethrow; // Hatayı yukarı fırlat ki UI'da gösterilebilsin
    }
  }

  // ==================== PATRON KOMUT OPERATIONS ====================

  /// Patron komut durumunu alır (root'ta /patronkomut)
  Future<bool> getPatronKomut() async {
    final snapshot = await _db.ref('patronkomut').get();
    if (!snapshot.exists || snapshot.value == null) return false;
    return snapshot.value as bool;
  }

  /// Patron komut durumunu günceller (root'ta /patronkomut)
  Future<void> setPatronKomut(bool value) async {
    await _db.ref('patronkomut').set(value);
  }

  /// Patron komut durumunu dinler (root'ta /patronkomut)
  Stream<bool> patronKomutStream() {
    return _db.ref('patronkomut').onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) return false;
      return event.snapshot.value as bool;
    });
  }

  // ==================== KOMUT OPERATIONS (Kullanıcı kapı açma) ====================

  /// /komut değerini alır
  Future<bool> getKomut() async {
    final snapshot = await _db.ref('komut').get();
    if (!snapshot.exists || snapshot.value == null) return false;
    return snapshot.value as bool;
  }

  /// /komut değerini günceller
  Future<void> setKomut(bool value) async {
    await _db.ref('komut').set(value);
  }

  /// /komut değerini true yapar ve 10 saniye sonra otomatik false yapar
  Future<void> setKomutWithAutoReset() async {
    await setKomut(true);
    // 10 saniye sonra otomatik false yap
    Future.delayed(const Duration(seconds: 10), () async {
      await setKomut(false);
    });
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
      final notifications =
          data.values
              .map(
                (v) => NotificationModel.fromMap(Map<String, dynamic>.from(v)),
              )
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

  Future<void> markNotificationAsRead(
    String notificationId,
    String userId,
  ) async {
    await _notificationsRef
        .child(notificationId)
        .child('readBy')
        .child(userId)
        .set(true);
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

  // ==================== AI PERFORMANCE OPERATIONS ====================

  /// Internal fields'ları filtreler ve sadece performans verilerini döndürür
  /// needs_update, xp_config gibi internal field'ları filtreler
  Map<String, dynamic>? _filterAIPerformanceData(Map<String, dynamic> data) {
    final filteredData = <String, dynamic>{};
    final performanceFields = [
      'daily_score',
      'general_score_xp',
      'career_level',
      'speed_label',
      'daily_mood',
      'action_items',
      'cluster_role', // 🧘 Derin Odak (Teknik/Yazılım) gibi
    ];

    for (final key in performanceFields) {
      if (data.containsKey(key)) {
        filteredData[key] = data[key];
      }
    }

    // If no performance data found, return null
    // But check if it's just internal fields (needs_update, xp_config)
    final hasInternalFieldsOnly =
        data.containsKey('needs_update') || data.containsKey('xp_config');

    if (filteredData.isEmpty && !hasInternalFieldsOnly) {
      debugPrint('⚠️ No performance fields found and no internal fields');
      return null;
    }

    // If only internal fields exist, return null
    if (filteredData.isEmpty && hasInternalFieldsOnly) {
      debugPrint(
        '⚠️ Only internal fields found (needs_update/xp_config), waiting for performance data...',
      );
      return null;
    }

    return filteredData;
  }

  /// AI Performance verisini dinler (users/{uid}/ai_performance)
  /// Real-time stream - her değişiklikte anında güncellenir
  /// Görev tamamlandığında, giriş/çıkış yapıldığında Python backend günceller
  /// Python backend gün içinde yapılan TÜM görevlerin toplam analizini yapmalı:
  /// - Toplam XP (tüm görevlerin difficultyPoints toplamı)
  /// - Günlük skor (gün içindeki performansa göre)
  /// - Seviye (XP'ye göre)
  /// - Hız durumu (görev tamamlama hızına göre)
  /// - Ruh hali (günlük aktiviteye göre)
  Stream<AIPerformance?> aiPerformanceStream(String uid) {
    final ref = _usersRef.child(uid).child('ai_performance');

    debugPrint(
      '🔍 AI Performance Stream başlatıldı: users/$uid/ai_performance',
    );
    debugPrint(
      '📌 Python backend şu path\'leri dinlemeli ve güncelleme yapmalı:',
    );
    debugPrint(
      '   1. users/$uid/task_completions/* (her görev tamamlandığında)',
    );
    debugPrint('   2. users/$uid/ai_performance/needs_update (trigger flag)');
    debugPrint('   3. users/$uid/attendance/* (giriş/çıkış)');
    debugPrint(
      '   → Python backend bu verileri analiz edip users/$uid/ai_performance path\'ine yazmalı',
    );

    return ref.onValue.asyncMap((event) async {
      debugPrint(
        '📡 AI Performance Stream event alındı - exists: ${event.snapshot.exists}',
      );

      if (!event.snapshot.exists || event.snapshot.value == null) {
        debugPrint('⚠️ AI Performance verisi yok veya null');
        debugPrint(
          '   → Python backend henüz veri yazmamış veya path yanlış olabilir',
        );
        return null;
      }

      final rawData = event.snapshot.value;

      // Handle both Map and dynamic types
      Map<String, dynamic> data;
      if (rawData is Map) {
        data = Map<String, dynamic>.from(rawData);
      } else {
        debugPrint('❌ Data is not a Map, returning null');
        return null;
      }

      debugPrint('📊 Firebase\'den gelen tüm keys: ${data.keys.toList()}');

      // Filter out internal fields using helper method
      final filteredData = _filterAIPerformanceData(data);
      if (filteredData == null) {
        debugPrint(
          '⚠️ Filtrelenmiş veri yok - sadece internal field\'lar (needs_update, xp_config) var',
        );
        debugPrint(
          '   → Python backend henüz performans verilerini yazmamış olabilir',
        );
        debugPrint(
          '   🔄 Fallback: task_completions\'dan hesaplama yapılıyor...',
        );
        // Fallback: task_completions'dan hesapla
        return _calculateAIPerformanceFromCompletions(uid);
      }

      debugPrint('✅ Filtrelenmiş veri keys: ${filteredData.keys.toList()}');

      // Parse and return performance data
      try {
        final performance = AIPerformance.fromMap(filteredData);
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        debugPrint('✅ AI PERFORMANCE GÜNCELLENDİ:');
        debugPrint('   📊 Günlük Skor: ${performance.dailyScore}');
        debugPrint('   ⭐ Toplam XP: ${performance.generalScoreXp}');
        debugPrint('   📈 Seviye: ${performance.careerLevel}');
        debugPrint('   ⚡ Hız: ${performance.speedLabel}');
        debugPrint('   😊 Ruh Hali: ${performance.dailyMood}');
        if (performance.clusterRole != null) {
          debugPrint('   👥 Rol: ${performance.clusterRole}');
        }
        debugPrint('   💡 Öneriler: ${performance.actionItems.length} adet');
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return performance;
      } catch (e) {
        debugPrint('❌ AI Performance parse error: $e');
        debugPrint('   Raw filtered data: $filteredData');
        return null;
      }
    });
  }

  Future<AIPerformance?> getAIPerformance(String uid) async {
    final ref = _usersRef.child(uid).child('ai_performance');
    debugPrint('🔍 getAIPerformance çağrıldı: users/$uid/ai_performance');

    final snapshot = await ref.get();
    debugPrint('📡 Snapshot exists: ${snapshot.exists}');

    if (!snapshot.exists || snapshot.value == null) {
      debugPrint('⚠️ AI Performance verisi yok');
      return null;
    }

    final rawData = snapshot.value;
    debugPrint('📦 Raw data type: ${rawData.runtimeType}');
    debugPrint('📦 Raw data: $rawData');

    if (rawData is! Map) {
      debugPrint('❌ Data is not a Map');
      return null;
    }

    final data = Map<String, dynamic>.from(rawData);
    debugPrint('📊 Data keys: ${data.keys.toList()}');

    // Filter out internal fields using helper method
    final filteredData = _filterAIPerformanceData(data);
    if (filteredData == null) {
      return null;
    }

    return AIPerformance.fromMap(filteredData);
  }

  /// Fallback: task_completions'dan AI Performance hesapla (Python backend yazmamışsa)
  Future<AIPerformance?> _calculateAIPerformanceFromCompletions(
    String uid,
  ) async {
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final completionsRef = _usersRef.child(uid).child('task_completions');
      final snapshot = await completionsRef.get();

      if (!snapshot.exists || snapshot.value == null) {
        debugPrint('⚠️ Fallback: task_completions yok');
        return null;
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final todayCompletions = <String, dynamic>{};
      int totalXP = 0;
      int taskCount = 0;

      for (final entry in data.entries) {
        final completion = Map<String, dynamic>.from(entry.value as Map);
        final completedAt = completion['completedAt'] as String?;
        if (completedAt != null && completedAt.startsWith(today)) {
          todayCompletions[entry.key] = completion;
          final points = completion['difficultyPoints'] as int? ?? 0;
          totalXP += points;
          taskCount++;
        }
      }

      if (todayCompletions.isEmpty) {
        debugPrint('⚠️ Fallback: Bugün tamamlanan görev yok');
        return null;
      }

      debugPrint('🔄 Fallback hesaplama: $taskCount görev, $totalXP XP');

      // Basit hesaplamalar
      final dailyScore = (totalXP * 10.0).clamp(0.0, 100.0);

      String careerLevel;
      if (totalXP < 10) {
        careerLevel = 'Başlangıç';
      } else if (totalXP < 50) {
        careerLevel = 'Orta Seviye';
      } else if (totalXP < 100) {
        careerLevel = 'İleri Seviye';
      } else {
        careerLevel = 'Uzman';
      }

      final speedLabel = taskCount > 5
          ? 'Hızlı'
          : (taskCount > 2 ? 'Normal' : 'Yavaş');
      final dailyMood = totalXP > 10
          ? 'Enerjik'
          : (totalXP > 5 ? 'Normal' : 'Yorgun');
      final actionItems = <String>[];
      if (taskCount < 3) {
        actionItems.add('Daha fazla görev tamamlayın');
      }
      if (totalXP < 5) {
        actionItems.add('Zor görevlere odaklanın');
      }

      // cluster_role'ü korumak için mevcut veriyi oku
      String? clusterRole;
      try {
        final aiPerfRef = _usersRef.child(uid).child('ai_performance');
        final clusterRoleSnapshot = await aiPerfRef.child('cluster_role').get();
        if (clusterRoleSnapshot.exists && clusterRoleSnapshot.value != null) {
          clusterRole = clusterRoleSnapshot.value.toString();
        }
      } catch (e) {
        debugPrint('⚠️ cluster_role okunamadı: $e');
      }

      final performance = AIPerformance(
        dailyScore: dailyScore,
        generalScoreXp: totalXP,
        careerLevel: careerLevel,
        speedLabel: speedLabel,
        dailyMood: dailyMood,
        actionItems: actionItems,
        clusterRole: clusterRole,
      );

      debugPrint('✅ Fallback hesaplama tamamlandı:');
      debugPrint('   📊 Günlük Skor: $dailyScore');
      debugPrint('   ⭐ Toplam XP: $totalXP');
      debugPrint('   📈 Seviye: $careerLevel');

      // Flutter tarafında Firebase'e yaz (Python backend yoksa)
      await _writeAIPerformanceToFirebase(uid, performance);
      debugPrint('   ✅ Firebase\'e yazıldı');

      return performance;
    } catch (e) {
      debugPrint('❌ Fallback hesaplama hatası: $e');
      return null;
    }
  }

  /// Flutter tarafında AI Performance'ı Firebase'e yaz
  Future<void> _writeAIPerformanceToFirebase(
    String uid,
    AIPerformance performance,
  ) async {
    try {
      final performanceRef = _usersRef.child(uid).child('ai_performance');

      // update() kullan - cluster_role'ü korumak için
      await performanceRef.update({
        'daily_score': performance.dailyScore,
        'general_score_xp': performance.generalScoreXp,
        'career_level': performance.careerLevel,
        'speed_label': performance.speedLabel,
        'daily_mood': performance.dailyMood,
        'action_items': performance.actionItems,
      });

      debugPrint(
        '✅ AI Performance Firebase\'e yazıldı: users/$uid/ai_performance',
      );
    } catch (e) {
      debugPrint('❌ AI Performance Firebase\'e yazılırken hata: $e');
    }
  }

  /// Gün içinde tamamlanan görevleri kontrol et ve AI Performance'ı güncelle
  Future<void> checkTodayTaskCompletions(String uid) async {
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final completionsRef = _usersRef.child(uid).child('task_completions');
      final snapshot = await completionsRef.get();

      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        final todayCompletions = <String, dynamic>{};

        for (final entry in data.entries) {
          final completion = Map<String, dynamic>.from(entry.value as Map);
          final completedAt = completion['completedAt'] as String?;
          if (completedAt != null && completedAt.startsWith(today)) {
            todayCompletions[entry.key] = completion;
          }
        }

        debugPrint(
          '📊 Bugün tamamlanan görevler: ${todayCompletions.length} adet',
        );
        if (todayCompletions.isNotEmpty) {
          int totalXP = 0;
          for (final completion in todayCompletions.values) {
            final points = completion['difficultyPoints'] as int? ?? 0;
            totalXP += points;
          }
          debugPrint('   Toplam XP: $totalXP');
          debugPrint(
            '   → Python backend bu verileri analiz edip ai_performance\'a yazmalı',
          );
        }
      } else {
        debugPrint('⚠️ task_completions path\'inde veri yok');
      }
    } catch (e) {
      debugPrint('❌ checkTodayTaskCompletions error: $e');
    }
  }

  /// Debug: Firebase path'ini ve mevcut veriyi kontrol et
  Future<void> debugAIPerformancePath(String uid) async {
    try {
      final ref = _usersRef.child(uid).child('ai_performance');
      final snapshot = await ref.get();

      debugPrint('🔍 DEBUG: AI Performance Path Check');
      debugPrint('   Path: users/$uid/ai_performance');
      debugPrint('   Exists: ${snapshot.exists}');

      // Bugünkü görev tamamlamalarını da kontrol et
      await checkTodayTaskCompletions(uid);

      if (snapshot.exists && snapshot.value != null) {
        debugPrint('   Value: ${snapshot.value}');
        if (snapshot.value is Map) {
          final data = Map<String, dynamic>.from(snapshot.value as Map);
          debugPrint('   Keys: ${data.keys.toList()}');
        }
      } else {
        debugPrint(
          '   ⚠️ Path exists but value is null or path does not exist',
        );
      }

      // Check needs_update
      final needsUpdateRef = ref.child('needs_update');
      final needsUpdateSnapshot = await needsUpdateRef.get();
      debugPrint('   needs_update exists: ${needsUpdateSnapshot.exists}');
      if (needsUpdateSnapshot.exists) {
        debugPrint('   needs_update value: ${needsUpdateSnapshot.value}');
      }

      // Check task_completions
      final taskCompletionsRef = _usersRef.child(uid).child('task_completions');
      final taskCompletionsSnapshot = await taskCompletionsRef.get();
      debugPrint(
        '   task_completions exists: ${taskCompletionsSnapshot.exists}',
      );
      if (taskCompletionsSnapshot.exists) {
        debugPrint(
          '   task_completions count: ${taskCompletionsSnapshot.children.length}',
        );
      }
    } catch (e) {
      debugPrint('❌ Debug check error: $e');
    }
  }

  // ==================== AI INTERACTION OPERATIONS ====================

  /// AI tahmin isteği gönderir (users/{uid}/ai_interaction/predict_request)
  Future<void> sendAIPredictRequest({
    required String uid,
    required String description,
    required String difficulty,
  }) async {
    await _usersRef
        .child(uid)
        .child('ai_interaction')
        .child('predict_request')
        .set({
          'description': description,
          'difficulty': difficulty,
          'status': 'pending',
          'timestamp': ServerValue.timestamp,
        });
  }

  /// AI tahmin cevabını dinler (users/{uid}/ai_interaction/predict_response)
  Stream<AIPredictResponse?> aiPredictResponseStream(String uid) {
    return _usersRef
        .child(uid)
        .child('ai_interaction')
        .child('predict_response')
        .onValue
        .map((event) {
          if (!event.snapshot.exists || event.snapshot.value == null) {
            return null;
          }
          final data = event.snapshot.value as Map<dynamic, dynamic>?;
          if (data == null) return null;
          return AIPredictResponse.fromMap(Map<String, dynamic>.from(data));
        });
  }

  Future<AIPredictResponse?> getAIPredictResponse(String uid) async {
    final snapshot = await _usersRef
        .child(uid)
        .child('ai_interaction')
        .child('predict_response')
        .get();
    if (!snapshot.exists || snapshot.value == null) return null;
    final data = Map<String, dynamic>.from(snapshot.value as Map);
    return AIPredictResponse.fromMap(data);
  }

  // ==================== COMPANY INSIGHTS OPERATIONS ====================

  /// Şirket insights verisini dinler (ai_company_insights)
  Stream<CompanyInsights> companyInsightsStream() {
    return _db.ref('ai_company_insights').onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        return CompanyInsights(
          riskAlertList: [],
          starPerformers: [],
          strategyMap: {},
        );
      }
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      return CompanyInsights.fromMap(data);
    });
  }

  Future<CompanyInsights> getCompanyInsights() async {
    final snapshot = await _db.ref('ai_company_insights').get();
    if (!snapshot.exists || snapshot.value == null) {
      return CompanyInsights(
        riskAlertList: [],
        starPerformers: [],
        strategyMap: {},
      );
    }
    final data = Map<String, dynamic>.from(snapshot.value as Map);
    return CompanyInsights.fromMap(data);
  }
}
