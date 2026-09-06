import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class AudioRecordingService {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _currentVisitId;

  bool get isRecording => _isRecording;
  String? get currentVisitId => _currentVisitId;

  /// Checks if microphone permission has been granted
  Future<bool> hasPermission() async {
    try {
      return await _recorder.hasPermission();
    } catch (_) {
      return false;
    }
  }

  /// Starts real audio recording for the given visit
  Future<void> startRecording(String visitId) async {
    final hasPerm = await hasPermission();
    if (!hasPerm) {
      throw StateError('Microphone permission not granted.');
    }

    String path = '';
    if (!kIsWeb) {
      final tempDir = await getTemporaryDirectory();
      path = '${tempDir.path}/visit_${visitId}_${DateTime.now().millisecondsSinceEpoch}.m4a';
    }

    const config = RecordConfig(
      encoder: AudioEncoder.aacLc,
      bitRate: 128000,
      sampleRate: 44100,
    );

    await _recorder.start(config, path: path);
    _isRecording = true;
    _currentVisitId = visitId;
  }

  /// Stops recording and returns the file path or blob URL
  Future<String?> stopRecording() async {
    if (!_isRecording) return null;
    try {
      final path = await _recorder.stop();
      _isRecording = false;
      _currentVisitId = null;
      return path;
    } catch (e) {
      _isRecording = false;
      _currentVisitId = null;
      rethrow;
    }
  }

  /// Cancels and deletes/discards the in-progress recording
  Future<void> cancelRecording() async {
    if (!_isRecording) return;
    try {
      await _recorder.cancel();
    } finally {
      _isRecording = false;
      _currentVisitId = null;
    }
  }

  /// Disposes internal resources
  void dispose() {
    _recorder.dispose();
  }
}
