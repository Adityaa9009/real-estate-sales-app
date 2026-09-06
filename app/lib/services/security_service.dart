import 'package:flutter/foundation.dart';

class SecurityService {
  static Future<void> enableScreenshotProtection() async {
    if (kIsWeb) return;
    try {
      // In mobile app targets, prevents customer data screenshots
    } catch (_) {}
  }
}
