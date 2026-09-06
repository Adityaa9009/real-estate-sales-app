import 'package:url_launcher/url_launcher.dart';

import 'database_service.dart';

class CallService {
  /// Masks phone number leaving only the last 4 digits (e.g. '******4285')
  static String maskPhone(String phone) {
    final cleaned = phone.trim();
    if (cleaned.length <= 4) return cleaned;
    final lastFour = cleaned.substring(cleaned.length - 4);
    final maskedPrefix = '*' * (cleaned.length - 4);
    return '$maskedPrefix$lastFour';
  }

  /// Fetches real phone from private subcollection on demand and launches dialer
  static Future<({bool success, String message})> callCustomerById(
    String customerId,
  ) async {
    final rawNumber = await DatabaseService.getCustomerPrivateContact(
      customerId,
    );
    if (rawNumber == null || rawNumber.trim().isEmpty) {
      return (
        success: false,
        message: 'Could not access customer contact number (unauthorized or missing record).',
      );
    }
    final launched = await makePhoneCall(rawNumber);
    if (!launched) {
      return (
        success: false,
        message: 'Could not launch telephone dialer. Please check device telephony capabilities.',
      );
    }
    return (success: true, message: 'Dialer opened.');
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
