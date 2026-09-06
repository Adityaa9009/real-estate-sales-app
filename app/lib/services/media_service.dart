import 'package:image_picker/image_picker.dart';

class MediaService {
  static final ImagePicker _picker = ImagePicker();

  /// Captures a customer verification photo with the device camera.
  /// Returns cross-platform XFile if captured, or null if cancelled / error.
  /// Does NOT simulate cloud upload or return fake URLs.
  static Future<XFile?> captureVerificationPhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return photo;
    } catch (_) {
      return null;
    }
  }
}
