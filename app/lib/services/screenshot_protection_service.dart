import 'package:screen_protector/screen_protector.dart';

class ScreenshotProtectionService {
  static Future<void> enable() async {
    await ScreenProtector.preventScreenshotOn();
    await ScreenProtector.protectDataLeakageOn();
  }

  static Future<void> disable() async {
    await ScreenProtector.preventScreenshotOff();
    await ScreenProtector.protectDataLeakageOff();
  }
}
