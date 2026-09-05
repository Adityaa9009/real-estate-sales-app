import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/visit.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../widgets/metric_card.dart';

class OutsideHomeView extends StatelessWidget {
  final VoidCallback onNavigateToVisits;

  const OutsideHomeView({super.key, required this.onNavigateToVisits});

  @override
  Widget build(BuildContext context) {
    final emp = AuthService.currentEmployee;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Field Operations: ${emp?.name ?? "Outside Rep"}',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Conduct customer site visits, capture client selfies, and record conversation audio.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),

          // KPI Stats
          StreamBuilder<List<Visit>>(
            stream: DatabaseService.getVisitsStream(),
            builder: (context, snapshot) {
              final visits = snapshot.data ?? [];
              final totalVisits = visits.length;
              final completedVisits = visits.where((v) => v.status == 'completed').length;
              final pendingVisits = visits.where((v) => v.status == 'scheduled' || v.status == 'in_progress').length;

              return Row(
                children: [
                  Expanded(
                    child: MetricCard(
                      title: 'Scheduled Visits',
                      value: '$totalVisits',
                      icon: Icons.calendar_today_rounded,
                      accentColor: AppColors.primary,
                      onTap: onNavigateToVisits,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MetricCard(
                      title: 'Pending Today',
                      value: '$pendingVisits',
                      icon: Icons.pending_actions_rounded,
                      accentColor: AppColors.warning,
                      onTap: onNavigateToVisits,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MetricCard(
                      title: 'Completed',
                      value: '$completedVisits',
                      icon: Icons.check_circle_outline_rounded,
                      accentColor: AppColors.success,
                      onTap: onNavigateToVisits,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 28),

          // Workflow Guidelines Card (PDF Page 11)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.checklist_rtl_rounded, color: AppColors.info, size: 22),
                    SizedBox(width: 10),
                    Text(
                      'Mandatory Visit Workflow (Company Policy)',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _workflowStep(1, 'Call customer to confirm time before heading out.'),
                _workflowStep(2, 'Tap "Reached Location" when meeting client to initiate audio recording.'),
                _workflowStep(3, 'Take and upload a verification selfie with the customer on site.'),
                _workflowStep(4, 'Tap "Completed Visit" to conclude visit, upload audio log, and finish.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _workflowStep(int num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: AppColors.primary.withAlpha(40),
            child: Text('$num', style: const TextStyle(fontSize: 10, color: AppColors.primaryLight, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
        ],
      ),
    );
  }
}
