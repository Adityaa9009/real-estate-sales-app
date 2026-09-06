import 'package:url_launcher/url_launcher.dart';

class CallService {
  /// Masks phone number leaving only the last 4 digits (e.g. '******4285')
  static String maskPhone(String phone) {
    final cleaned = phone.trim();
    if (cleaned.length <= 4) return cleaned;
    final lastFour = cleaned.substring(cleaned.length - 4);
    final maskedPrefix = '*' * (cleaned.length - 4);
    return '$maskedPrefix$lastFour';
  }

  /// Launches the system phone dialer with the real phone number
  static Future<bool> makePhoneCall(String rawPhoneNumber) async {
    final cleanNumber = rawPhoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri(scheme: 'tel', path: cleanNumber);
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
