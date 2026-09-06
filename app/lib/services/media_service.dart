import 'package:image_picker/image_picker.dart';

class MediaService {
  /// Honest flag indicating Firebase Cloud Storage status
  static const bool isStorageConfigured = false;

  static const String storageDisabledNotice =
      'Firebase Cloud Storage is unconfigured. Cloud media proofs and remote audio recording are disabled.';

  static final ImagePicker _picker = ImagePicker();

  /// Captures a customer verification photo with the device camera.
  /// Returns local path if captured, or null if cancelled / error.
  /// Does NOT simulate cloud upload or return fake URLs.
  static Future<String?> captureVerificationPhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return photo?.path;
    } catch (_) {
      return null;
    }
  }
}
