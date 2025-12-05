import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:office_control/models/attendance_model.dart';
import 'package:office_control/services/database_service.dart';
import 'package:office_control/services/door_access_service.dart';
import 'package:office_control/services/location_service.dart';

class AttendanceProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final DoorAccessService _doorService = DoorAccessService();

  DailyAttendance? _todayAttendance;
  List<DailyAttendance> _history = [];
  bool _isLoading = false;
  bool _isDoorOperating = false;
  String? _error;
  String? _userId;
  StreamSubscription? _attendanceSubscription;

  DailyAttendance? get todayAttendance => _todayAttendance;
  List<DailyAttendance> get history => _history;
  bool get isLoading => _isLoading;
  bool get isDoorOperating => _isDoorOperating;
  String? get error => _error;

  String get formattedTodayHours => _todayAttendance?.formattedTotalTime ?? '0h 0m';
  
  AttendanceRecord? get latestActivity => _todayAttendance?.latestActivity;
  
  List<AttendanceRecord> get todayRecords => _todayAttendance?.records ?? [];

  Future<void> initialize(String userId) async {
    _userId = userId;
    await _doorService.initialize();
    _subscribeToTodayAttendance();
    await loadHistory();
  }

  void _subscribeToTodayAttendance() {
    _attendanceSubscription?.cancel();
    if (_userId == null) return;

    _attendanceSubscription = _dbService.todayAttendanceStream(_userId!).listen(
      (attendance) {
        _todayAttendance = attendance;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        notifyListeners();
      },
    );
  }

  Future<void> loadHistory({int days = 30}) async {
    if (_userId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      _history = await _dbService.getAttendanceHistory(_userId!, days: days);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<DoorAccessResult> openDoor(AttendanceType type) async {
    if (_userId == null) {
      return DoorAccessResult(
        status: DoorAccessStatus.unknown,
        message: 'Kullanıcı oturumu bulunamadı.',
      );
    }

    _isDoorOperating = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _doorService.attemptDoorOpen(
        userId: _userId!,
        type: type,
      );

      _isDoorOperating = false;
      
      if (result.status != DoorAccessStatus.success) {
        _error = result.message;
      }
      
      notifyListeners();
      return result;
    } catch (e) {
      _isDoorOperating = false;
      _error = e.toString();
      notifyListeners();
      return DoorAccessResult(
        status: DoorAccessStatus.unknown,
        message: e.toString(),
      );
    }
  }

  Future<bool> checkLocation() async {
    return await _doorService.checkLocationOnly();
  }

  Future<LocationCheckResult> getDetailedLocationCheck() async {
    return await _doorService.getDetailedLocationCheck();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _attendanceSubscription?.cancel();
    super.dispose();
  }
}

