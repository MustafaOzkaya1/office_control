import 'package:office_control/models/attendance_model.dart';
import 'package:office_control/models/office_location_model.dart';
import 'package:office_control/services/database_service.dart';
import 'package:office_control/services/esp32_service.dart';
import 'package:office_control/services/location_service.dart';
import 'package:uuid/uuid.dart';

enum DoorAccessStatus {
  success,
  locationError,
  espError,
  notApproved,
  unknown,
}

class DoorAccessResult {
  final DoorAccessStatus status;
  final String message;
  final AttendanceRecord? record;

  DoorAccessResult({
    required this.status,
    required this.message,
    this.record,
  });
}

class DoorAccessService {
  final LocationService _locationService = LocationService();
  final ESP32Service _esp32Service = ESP32Service();
  final DatabaseService _dbService = DatabaseService();
  final Uuid _uuid = const Uuid();

  OfficeLocation? _officeLocation;

  Future<void> initialize() async {
    _officeLocation = await _dbService.getOfficeLocation();
    if (_officeLocation != null) {
      _esp32Service.configure(
        ipAddress: _officeLocation!.espIpAddress,
        ssid: _officeLocation!.espSsid,
      );
    }
  }

  Future<void> refreshOfficeLocation() async {
    _officeLocation = await _dbService.getOfficeLocation();
    if (_officeLocation != null) {
      _esp32Service.configure(
        ipAddress: _officeLocation!.espIpAddress,
        ssid: _officeLocation!.espSsid,
      );
    }
  }

  Future<DoorAccessResult> attemptDoorOpen({
    required String userId,
    required AttendanceType type,
  }) async {
    // 1. Check if office location is configured
    if (_officeLocation == null) {
      await refreshOfficeLocation();
    }

    if (_officeLocation == null) {
      return DoorAccessResult(
        status: DoorAccessStatus.unknown,
        message: 'Ofis konumu yapılandırılmamış. Yöneticiyle iletişime geçin.',
      );
    }

    // 2. Check location
    final locationCheck = await _locationService.checkLocationForDoorAccess(_officeLocation!);
    if (!locationCheck.success) {
      return DoorAccessResult(
        status: DoorAccessStatus.locationError,
        message: locationCheck.message,
      );
    }

    // 3. Send command to ESP32
    final espResponse = await _esp32Service.openDoor();
    if (!espResponse.success) {
      return DoorAccessResult(
        status: DoorAccessStatus.espError,
        message: espResponse.message,
      );
    }

    // 4. Record attendance
    final record = AttendanceRecord(
      id: _uuid.v4(),
      userId: userId,
      type: type,
      timestamp: DateTime.now(),
      location: _officeLocation!.name,
      doorId: _officeLocation!.id,
    );

    try {
      await _dbService.recordAttendance(record);
    } catch (e) {
      // Door opened but attendance recording failed - still success but log error
      return DoorAccessResult(
        status: DoorAccessStatus.success,
        message: 'Kapı açıldı. (Kayıt hatası: $e)',
        record: record,
      );
    }

    return DoorAccessResult(
      status: DoorAccessStatus.success,
      message: type == AttendanceType.entry 
          ? 'Giriş kaydedildi. Hoş geldiniz!' 
          : 'Çıkış kaydedildi. İyi günler!',
      record: record,
    );
  }

  Future<bool> checkLocationOnly() async {
    if (_officeLocation == null) {
      await refreshOfficeLocation();
    }
    if (_officeLocation == null) return false;
    
    return await _locationService.isWithinOfficeRange(_officeLocation!);
  }

  Future<LocationCheckResult> getDetailedLocationCheck() async {
    if (_officeLocation == null) {
      await refreshOfficeLocation();
    }
    if (_officeLocation == null) {
      return LocationCheckResult(
        success: false,
        message: 'Ofis konumu yapılandırılmamış.',
        distanceMeters: null,
      );
    }
    
    return await _locationService.checkLocationForDoorAccess(_officeLocation!);
  }
}

