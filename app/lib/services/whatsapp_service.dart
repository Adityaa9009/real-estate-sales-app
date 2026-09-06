import 'package:url_launcher/url_launcher.dart';

import 'database_service.dart';

class WhatsAppService {
  static String _cleanPhone(String phone) {
    var digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 10) {
      digits = '91$digits';
    }
    return digits;
  }

  /// Sends interested message using customer ID (fetching private contact on demand)
  static Future<({bool success, String message})>
  sendInterestedMessageByCustomerId({
    required String customerId,
    required String customerName,
    String? propertyName,
  }) async {
    final rawPhone = await DatabaseService.getCustomerPrivateContact(
      customerId,
    );
    if (rawPhone == null || rawPhone.trim().isEmpty) {
      return (
        success: false,
        message: 'Could not access customer contact phone (unauthorized or missing record).',
      );
    }
    return sendInterestedMessage(
      customerName: customerName,
      customerPhone: rawPhone,
      propertyName: propertyName,
    );
  }

  /// Sends not-interested message using customer ID (fetching private contact on demand)
  static Future<({bool success, String message})>
  sendNotInterestedMessageByCustomerId({
    required String customerId,
    required String customerName,
  }) async {
    final rawPhone = await DatabaseService.getCustomerPrivateContact(
      customerId,
    );
    if (rawPhone == null || rawPhone.trim().isEmpty) {
      return (
        success: false,
        message: 'Could not access customer contact phone (unauthorized or missing record).',
      );
    }
    return sendNotInterestedMessage(
      customerName: customerName,
      customerPhone: rawPhone,
    );
  }

  static Future<({bool success, String message})> sendInterestedMessage({
    required String customerName,
    required String customerPhone,
    String? propertyName,
  }) async {
    final cleanPhone = _cleanPhone(customerPhone);
    final prop = propertyName ?? 'Luxury Heights Residency';
    final message =
        'Hello $customerName,\n\n'
        'Thank you for showing interest in $prop!\n\n'
        'Attached is our official property brochure and project floor plans.\n\n'
        'Our sales team will schedule a personalized site visit for you shortly. Please reply if you have any questions.\n\n'
        'Best regards,\nReal Estate Sales Team';

    final launched = await _launchWhatsApp(cleanPhone, message);
    if (!launched) {
      return (
        success: false,
        message: 'Could not open WhatsApp. Please ensure WhatsApp or WhatsApp Web is accessible.',
      );
    }
    return (success: true, message: 'WhatsApp opened.');
  }

  static Future<({bool success, String message})> sendNotInterestedMessage({
    required String customerName,
    required String customerPhone,
  }) async {
    final cleanPhone = _cleanPhone(customerPhone);
    final message =
        'Hello $customerName,\n\n'
        'Thank you for taking the time to speak with our sales team today.\n\n'
        'We understand this may not be the right time. If you ever require assistance with properties, investments, or dream homes in the future, please feel free to reach out to us anytime.\n\n'
        'Warm regards,\nReal Estate Sales Team';

    final launched = await _launchWhatsApp(cleanPhone, message);
    if (!launched) {
      return (
        success: false,
        message: 'Could not open WhatsApp. Please ensure WhatsApp or WhatsApp Web is accessible.',
      );
    }
    return (success: true, message: 'WhatsApp opened.');
  }

  static Future<bool> _launchWhatsApp(String phone, String text) async {
    final url = 'https://wa.me/$phone?text=${Uri.encodeComponent(text)}';
    final uri = Uri.parse(url);
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
