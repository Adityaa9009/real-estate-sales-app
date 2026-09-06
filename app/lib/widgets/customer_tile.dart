import 'package:flutter/material.dart';

import '../models/customer.dart';
import '../config/app_theme.dart';
import '../services/call_service.dart';
import '../services/whatsapp_service.dart';

class CustomerTile extends StatelessWidget {
  final Customer customer;
  final VoidCallback? onMarkInterested;
  final VoidCallback? onMarkNotInterested;
  final VoidCallback? onScheduleVisit;
  final bool showActions;

  const CustomerTile({
    super.key,
    required this.customer,
    this.onMarkInterested,
    this.onMarkNotInterested,
    this.onScheduleVisit,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  customer.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: customer.status.color.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: customer.status.color.withAlpha(100),
                  ),
                ),
                child: Text(
                  customer.status.label,
                  style: TextStyle(
                    color: customer.status.color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.phone_outlined,
                size: 14,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                'Phone: ${customer.maskedPhone}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontFamily: 'monospace',
                ),
              ),
              if (customer.budget != null) ...[
                const SizedBox(width: 12),
                const Text('•', style: TextStyle(color: AppColors.textMuted)),
                const SizedBox(width: 12),
                Text(
                  customer.budget!,
                  style: const TextStyle(fontSize: 12, color: AppColors.info),
                ),
              ],
            ],
          ),
          if (customer.propertyNotes != null) ...[
            const SizedBox(height: 6),
            Text(
              customer.propertyNotes!,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (showActions) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                // Real Call Button (fetches private contact on-demand)
                IconButton.filledTonal(
                  icon: const Icon(Icons.call_rounded, size: 18),
                  tooltip: 'Call Customer',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary.withAlpha(40),
                    foregroundColor: AppColors.primary,
                  ),
                  onPressed: () async {
                    final res = await CallService.callCustomerById(customer.id);
                    if (!res.success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(res.message),
                          backgroundColor: AppColors.danger,
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(width: 8),

                // WhatsApp Button (fetches private contact on-demand)
                IconButton.filledTonal(
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  tooltip: 'WhatsApp Message',
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366).withAlpha(40),
                    foregroundColor: const Color(0xFF25D366),
                  ),
                  onPressed: () async {
                    final res =
                        await WhatsAppService.sendInterestedMessageByCustomerId(
                          customerId: customer.id,
                          customerName: customer.name,
                        );
                    if (!res.success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(res.message),
                          backgroundColor: AppColors.danger,
                        ),
                      );
                    }
                  },
                ),
                const Spacer(),

                // Mark Interested Action
                if (onMarkInterested != null)
                  TextButton.icon(
                    onPressed: onMarkInterested,
                    icon: const Icon(Icons.thumb_up_alt_rounded, size: 16),
                    label: const Text('Interested'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.success,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),

                // Mark Not Interested Action
                if (onMarkNotInterested != null)
                  TextButton.icon(
                    onPressed: onMarkNotInterested,
                    icon: const Icon(Icons.thumb_down_alt_rounded, size: 16),
                    label: const Text('Not Interested'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),

                // Schedule Visit Action
                if (onScheduleVisit != null)
                  ElevatedButton.icon(
                    onPressed: onScheduleVisit,
                    icon: const Icon(Icons.calendar_month_rounded, size: 15),
                    label: const Text('Schedule Visit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
