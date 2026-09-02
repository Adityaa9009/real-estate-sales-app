import 'package:geolocator/geolocator.dart';
import '../config/office_location.dart';

class LocationService {
  static Future<Position> getCurrentPosition() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      throw Exception('Location permission is required to use this app');
    }
    return Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  static double distanceToOfficeMeters(Position position) {
    return Geolocator.distanceBetween(
      OfficeLocation.latitude,
      OfficeLocation.longitude,
      position.latitude,
      position.longitude,
    );
  }

  static Future<bool> isInsideOffice() async {
    final position = await getCurrentPosition();
    return distanceToOfficeMeters(position) <= OfficeLocation.allowedRadiusMeters;
  }

  static Stream<Position> watchPosition() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 20,
      ),
    );
  }
}
