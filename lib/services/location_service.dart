import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:office_control/models/office_location_model.dart';

class LocationService {
  /// Only checks permission status without requesting (safe to call anytime)
  Future<bool> checkPermissionStatus() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (e) {
      return false;
    }
  }

  /// Checks and requests permission if needed
  /// Returns (hasPermission, isDeniedForever)
  Future<(bool, bool)> checkAndRequestPermissionWithStatus() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return (false, false);
      }

      LocationPermission permission = await Geolocator.checkPermission();

      // İzin zaten verilmiş
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        return (true, false);
      }

      // İzin reddedilmiş, tekrar iste
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse) {
          return (true, false);
        }
        if (permission == LocationPermission.deniedForever) {
          return (false, true);
        }
        return (false, false);
      }

      // İzin kalıcı olarak reddedilmiş
      if (permission == LocationPermission.deniedForever) {
        return (false, true);
      }

      return (false, false);
    } catch (e) {
      return (false, false);
    }
  }

  /// Checks and requests permission if needed (backward compatibility)
  Future<bool> checkAndRequestPermission() async {
    final (hasPermission, _) = await checkAndRequestPermissionWithStatus();
    return hasPermission;
  }

  Future<Position?> getCurrentPosition() async {
    final hasPermission = await checkAndRequestPermission();
    if (!hasPermission) return null;

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      );
    } catch (e) {
      return null;
    }
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // meters

    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * math.pi / 180;
  }

  Future<bool> isWithinOfficeRange(OfficeLocation office) async {
    final position = await getCurrentPosition();
    if (position == null) return false;

    final distance = calculateDistance(
      position.latitude,
      position.longitude,
      office.latitude,
      office.longitude,
    );

    return distance <= office.radiusMeters;
  }

  Future<LocationCheckResult> checkLocationForDoorAccess(
    OfficeLocation office,
  ) async {
    final (hasPermission, isDeniedForever) =
        await checkAndRequestPermissionWithStatus();
    if (!hasPermission) {
      return LocationCheckResult(
        success: false,
        message: isDeniedForever
            ? 'Konum izni kalıcı olarak reddedilmiş. Lütfen ayarlardan izin verin.'
            : 'Konum izni gerekli. Lütfen izin verin.',
        distanceMeters: null,
      );
    }

    final position = await getCurrentPosition();
    if (position == null) {
      return LocationCheckResult(
        success: false,
        message: 'Konum alınamadı. Lütfen tekrar deneyin.',
        distanceMeters: null,
      );
    }

    final distance = calculateDistance(
      position.latitude,
      position.longitude,
      office.latitude,
      office.longitude,
    );

    if (distance <= office.radiusMeters) {
      return LocationCheckResult(
        success: true,
        message: 'Konum doğrulandı. Kapı açılabilir.',
        distanceMeters: distance,
      );
    } else {
      return LocationCheckResult(
        success: false,
        message: 'Ofise çok uzaksınız. (${distance.toStringAsFixed(0)}m)',
        distanceMeters: distance,
      );
    }
  }
}

class LocationCheckResult {
  final bool success;
  final String message;
  final double? distanceMeters;

  LocationCheckResult({
    required this.success,
    required this.message,
    this.distanceMeters,
  });
}
