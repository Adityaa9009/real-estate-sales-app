import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

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

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty || parts.first.isEmpty) return 'C';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(customer.name);
    final statusColor = customer.status.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: CardStyles.secondary(borderRadius: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Avatar + Name + Status Pill
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(35),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: statusColor.withAlpha(90), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withAlpha(45),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.phone_rounded,
                              size: 13,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              customer.maskedPhone,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withAlpha(100), width: 1),
                    ),
                    child: Text(
                      customer.status.label,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              // Metadata Pills: Budget & Notes
              if (customer.budget != null || customer.propertyNotes != null) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (customer.budget != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.info.withAlpha(25),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.info.withAlpha(70)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.currency_rupee_rounded, size: 12, color: AppColors.info),
                            const SizedBox(width: 2),
                            Text(
                              customer.budget!,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.info,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (customer.propertyNotes != null)
                      Text(
                        customer.propertyNotes!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ],

              // Actions Footer
              if (showActions) ...[
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.surfaceBorder),
                const SizedBox(height: 10),
                Row(
                  children: [
                    // Call Button
                    IconButton.filledTonal(
                      icon: const Icon(Icons.call_rounded, size: 17),
                      tooltip: 'Call Customer',
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.primary.withAlpha(35),
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.all(8),
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

                    // WhatsApp Button
                    IconButton.filledTonal(
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 17),
                      tooltip: 'WhatsApp Message',
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366).withAlpha(35),
                        foregroundColor: const Color(0xFF25D366),
                        padding: const EdgeInsets.all(8),
                      ),
                      onPressed: () async {
                        final res = await WhatsAppService.sendInterestedMessageByCustomerId(
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
                        icon: const Icon(Icons.thumb_up_alt_rounded, size: 15),
                        label: const Text('Interested'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.success,
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),

                    // Mark Not Interested Action
                    if (onMarkNotInterested != null)
                      TextButton.icon(
                        onPressed: onMarkNotInterested,
                        icon: const Icon(Icons.thumb_down_alt_rounded, size: 15),
                        label: const Text('Not Interested'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),

                    // Schedule Visit Action
                    if (onScheduleVisit != null)
                      ElevatedButton.icon(
                        onPressed: onScheduleVisit,
                        icon: const Icon(Icons.calendar_month_rounded, size: 14),
                        label: const Text('Schedule Visit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.05, end: 0);
  }
}

