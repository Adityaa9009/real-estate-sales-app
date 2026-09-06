import 'dart:async';
import 'package:image_picker/image_picker.dart';

class MediaService {
  static final ImagePicker _picker = ImagePicker();

  static Future<String?> pickSelfieWithCustomer() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (photo != null) return photo.path;

      final XFile? galleryPhoto = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      return galleryPhoto?.path;
    } catch (_) {
      return 'demo_selfie_${DateTime.now().millisecondsSinceEpoch}.jpg';
    }
  }

  static bool _isRecording = false;
  static DateTime? _recordingStartTime;
  static Timer? _recordingTimer;
  static int _elapsedSeconds = 0;

  static bool get isRecording => _isRecording;
  static int get elapsedSeconds => _elapsedSeconds;

  static void startRecording({required void Function(int seconds) onTick}) {
    _isRecording = true;
    _recordingStartTime = DateTime.now();
    _elapsedSeconds = 0;
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsedSeconds++;
      onTick(_elapsedSeconds);
    });
  }

  static ({String recordingPath, Duration duration}) stopRecording() {
    _recordingTimer?.cancel();
    _isRecording = false;
    final duration = DateTime.now().difference(_recordingStartTime ?? DateTime.now());
    final path = 'audio_visit_${DateTime.now().millisecondsSinceEpoch}.m4a';
    return (recordingPath: path, duration: duration);
  }
}
