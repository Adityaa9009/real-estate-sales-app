import 'package:geolocator/geolocator.dart';
import '../config/office_location.dart';

class LocationService {
  static bool _mockInsideOffice = true;
  static bool get isMockInsideOffice => _mockInsideOffice;

  static void setMockInsideOffice(bool value) {
    _mockInsideOffice = value;
  }

  static Future<({bool isInside, double distanceMeters, Position? position})> checkOfficeGeofence() async {
    try {
      if (_mockInsideOffice) {
        return (isInside: true, distanceMeters: 45.0, position: null);
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return (isInside: _mockInsideOffice, distanceMeters: 50.0, position: null);
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return (isInside: _mockInsideOffice, distanceMeters: 50.0, position: null);
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        OfficeLocation.latitude,
        OfficeLocation.longitude,
      );

      final isInside = distance <= OfficeLocation.geofenceRadiusMeters;
      return (isInside: isInside, distanceMeters: distance, position: position);
    } catch (_) {
      return (isInside: _mockInsideOffice, distanceMeters: _mockInsideOffice ? 50.0 : 450.0, position: null);
    }
  }
}
