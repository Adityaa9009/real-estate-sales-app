import 'package:firebase_storage/firebase_storage.dart';

class StorageAvailabilityService {
  static bool? _cachedAvailability;

  /// Attempts a trivial, harmless Storage operation (checking a known
  /// reference's metadata) to detect whether Cloud Storage is actually
  /// provisioned and reachable on this Firebase project.
  static Future<bool> isStorageAvailable({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedAvailability != null) {
      return _cachedAvailability!;
    }
    try {
      await FirebaseStorage.instance.ref('_healthcheck').getMetadata();
      _cachedAvailability = true;
      return true;
    } on FirebaseException catch (e) {
      // 'object-not-found' still means Storage itself IS reachable —
      // only 'unknown'/'unauthorized'/config errors mean it's not provisioned.
      if (e.code == 'object-not-found') {
        _cachedAvailability = true;
        return true;
      }
      _cachedAvailability = false;
      return false;
    } catch (_) {
      _cachedAvailability = false;
      return false;
    }
  }

  /// Returns cached availability, or false if not yet checked
  static bool get cachedStatus => _cachedAvailability ?? false;

  /// Resets or overrides cached status (useful for unit testing)
  static void setMockAvailability(bool? value) {
    _cachedAvailability = value;
  }
}
