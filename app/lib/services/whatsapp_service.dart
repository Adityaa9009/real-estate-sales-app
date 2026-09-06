import 'package:url_launcher/url_launcher.dart';

class WhatsAppService {
  static String _cleanPhone(String phone) {
    var digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 10) {
      digits = '91$digits';
    }
    return digits;
  }

  static Future<bool> sendInterestedMessage({
    required String customerName,
    required String customerPhone,
    String? propertyName,
  }) async {
    final cleanPhone = _cleanPhone(customerPhone);
    final prop = propertyName ?? 'Luxury Heights Residency';
    final message = 'Hello $customerName,\n\n'
        'Thank you for showing interest in $prop!\n\n'
        'Attached is our official property brochure and project floor plans:\n'
        'https://realestate-demo.web.app/brochures/catalog.pdf\n\n'
        'Our executive team will schedule a personalized site visit for you shortly. Please reply if you have any questions.\n\n'
        'Best regards,\nReal Estate Sales Team';

    return _launchWhatsApp(cleanPhone, message);
  }

  static Future<bool> sendNotInterestedMessage({
    required String customerName,
    required String customerPhone,
  }) async {
    final cleanPhone = _cleanPhone(customerPhone);
    final message = 'Hello $customerName,\n\n'
        'Thank you for taking the time to speak with our sales team today.\n\n'
        'We understand this may not be the right time. If you ever require assistance with properties, investments, or dream homes in the future, please feel free to reach out to us anytime.\n\n'
        'Warm regards,\nReal Estate Sales Team';

    return _launchWhatsApp(cleanPhone, message);
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
