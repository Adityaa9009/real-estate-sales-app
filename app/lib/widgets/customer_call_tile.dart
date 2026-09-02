import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/customer.dart';

class CustomerCallTile extends StatelessWidget {
  final Customer customer;
  final VoidCallback onInterested;
  final VoidCallback onNotInterested;

  const CustomerCallTile({
    super.key,
    required this.customer,
    required this.onInterested,
    required this.onNotInterested,
  });

  Future<void> _call() async {
    final uri = Uri(scheme: 'tel', path: customer.phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name: ${customer.name}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                Text('Phone: ${customer.maskedPhone}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.call, color: Colors.white), onPressed: _call),
          IconButton(
            icon: const Icon(Icons.thumb_up, color: Colors.greenAccent),
            onPressed: onInterested,
          ),
          IconButton(
            icon: const Icon(Icons.thumb_down, color: Colors.redAccent),
            onPressed: onNotInterested,
          ),
        ],
      ),
    );
  }
}
