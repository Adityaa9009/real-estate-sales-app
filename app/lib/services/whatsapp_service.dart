import 'package:url_launcher/url_launcher.dart';
import '../models/customer.dart';
import 'customer_service.dart';

class WhatsAppService {
  static const String propertyDocUrl = 'https://YOUR_STORAGE_HOST/property-brochure.pdf';

  static Future<void> sendInterestedMessage(Customer customer) async {
    final message =
        'Hi ${customer.name}, thank you for showing interest in our property! '
        'Here is the property document: $propertyDocUrl';
    await _launch(customer.phone, message);
    await CustomerService.markWhatsappSent(customer.id);
  }

  static Future<void> sendNotInterestedMessage(Customer customer) async {
    final message =
        'Hi ${customer.name}, thank you for your time. '
        'Here is our property document: $propertyDocUrl. '
        'If you are interested in the future, please feel free to contact us.';
    await _launch(customer.phone, message);
    await CustomerService.markWhatsappSent(customer.id);
  }

  static Future<void> _launch(String phone, String message) async {
    final uri = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Could not open WhatsApp');
    }
  }
}
