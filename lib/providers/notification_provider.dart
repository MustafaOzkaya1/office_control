import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:office_control/models/notification_model.dart';
import 'package:office_control/services/database_service.dart';
import 'package:uuid/uuid.dart';

class NotificationProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final Uuid _uuid = const Uuid();

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;
  String? _userId;
  StreamSubscription? _notificationsSubscription;
  StreamSubscription? _unreadCountSubscription;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasUnread => _unreadCount > 0;

  List<NotificationModel> get unreadNotifications =>
      _notifications.where((n) => !n.isReadByUser(_userId ?? '')).toList();

  List<NotificationModel> getNotificationsByCategory(NotificationCategory category) =>
      _notifications.where((n) => n.category == category).toList();

  void setUserId(String userId) {
    if (_userId == userId) return;
    _userId = userId;
    _subscribeToNotifications();
  }

  void _subscribeToNotifications() {
    _notificationsSubscription?.cancel();
    _unreadCountSubscription?.cancel();
    
    if (_userId == null) return;

    _notificationsSubscription = _dbService.notificationsStream(userId: _userId).listen(
      (notifications) {
        _notifications = notifications;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );

    _unreadCountSubscription = _dbService.unreadNotificationCountStream(_userId!).listen(
      (count) {
        _unreadCount = count;
        notifyListeners();
      },
    );
  }

  Future<bool> createNotification({
    required String title,
    required String message,
    required NotificationCategory category,
    NotificationPriority priority = NotificationPriority.normal,
    required String createdBy,
    DateTime? expiresAt,
    List<String>? targetUserIds,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final notification = NotificationModel(
        id: _uuid.v4(),
        title: title,
        message: message,
        category: category,
        priority: priority,
        createdBy: createdBy,
        createdAt: DateTime.now(),
        expiresAt: expiresAt,
        targetUserIds: targetUserIds,
      );

      await _dbService.createNotification(notification);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> markAsRead(String notificationId) async {
    if (_userId == null) return;
    
    try {
      await _dbService.markNotificationAsRead(notificationId, _userId!);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    if (_userId == null) return;
    
    try {
      await _dbService.markAllNotificationsAsRead(_userId!);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _dbService.deleteNotification(notificationId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _notificationsSubscription?.cancel();
    _unreadCountSubscription?.cancel();
    super.dispose();
  }
}

