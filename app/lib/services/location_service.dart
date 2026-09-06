import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../config/office_location.dart';

enum GeofenceFailureReason {
  gpsDisabled('gps_disabled'),
  permissionDenied('permission_denied'),
  permissionDeniedForever('permission_denied_forever'),
  timeout('timeout'),
  locationError('location_error'),
  outsideGeofence('outside_geofence');

  final String code;
  const GeofenceFailureReason(this.code);
}

class GeofenceCheckResult {
  final bool isInside;
  final double distanceMeters;
  final Position? position;
  final String message;
  final GeofenceFailureReason? failureReason;

  const GeofenceCheckResult({
    required this.isInside,
    required this.distanceMeters,
    this.position,
    required this.message,
    this.failureReason,
  });
}

class LocationService {
  /// Auto-detects device GPS location and verifies if within office perimeter.
  /// Fails closed: any permission refusal, disabled GPS, timeout, or location error denies access.
  static Future<GeofenceCheckResult> checkOfficeGeofence({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const GeofenceCheckResult(
          isInside: false,
          distanceMeters: 9999.0,
          position: null,
          message: 'Device location services (GPS) are disabled. Please turn on location.',
          failureReason: GeofenceFailureReason.gpsDisabled,
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return const GeofenceCheckResult(
            isInside: false,
            distanceMeters: 9999.0,
            position: null,
            message: 'Location permission was denied. Inside Sales requires verified office location.',
            failureReason: GeofenceFailureReason.permissionDenied,
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return const GeofenceCheckResult(
          isInside: false,
          distanceMeters: 9999.0,
          position: null,
          message: 'Location permission permanently denied. Enable location in device/browser settings.',
          failureReason: GeofenceFailureReason.permissionDeniedForever,
        );
      }

      final position =
          await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
            ),
          ).timeout(
            timeout,
            onTimeout: () {
              throw TimeoutException(
                'GPS signal timed out after ${timeout.inSeconds} seconds.',
              );
            },
          );

      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        OfficeLocation.latitude,
        OfficeLocation.longitude,
      );

      final isInside = distance <= OfficeLocation.geofenceRadiusMeters;
      return GeofenceCheckResult(
        isInside: isInside,
        distanceMeters: distance,
        position: position,
        message: isInside
            ? 'Verified inside office (${distance.toStringAsFixed(1)}m from center)'
            : 'Outside office (${distance.toStringAsFixed(1)}m away, limit: ${OfficeLocation.geofenceRadiusMeters.toStringAsFixed(0)}m)',
        failureReason: isInside ? null : GeofenceFailureReason.outsideGeofence,
      );
    } on TimeoutException catch (e) {
      return GeofenceCheckResult(
        isInside: false,
        distanceMeters: 9999.0,
        position: null,
        message: e.message ?? 'GPS request timed out.',
        failureReason: GeofenceFailureReason.timeout,
      );
    } catch (e) {
      return GeofenceCheckResult(
        isInside: false,
        distanceMeters: 9999.0,
        position: null,
        message: 'Location verification error: $e',
        failureReason: GeofenceFailureReason.locationError,
      );
    }
  }
}
