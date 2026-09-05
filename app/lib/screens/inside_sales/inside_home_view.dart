import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../config/office_location.dart';
import '../../models/broadcast_message.dart';
import '../../models/customer.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/location_service.dart';
import '../../widgets/metric_card.dart';

class InsideHomeView extends StatefulWidget {
  final VoidCallback onNavigateToCalls;
  final VoidCallback onNavigateToInterested;

  const InsideHomeView({
    super.key,
    required this.onNavigateToCalls,
    required this.onNavigateToInterested,
  });

  @override
  State<InsideHomeView> createState() => _InsideHomeViewState();
}

class _InsideHomeViewState extends State<InsideHomeView> {
  bool _isInside = true;
  double _distance = 45.0;

  @override
  void initState() {
    super.initState();
    _checkLocation();
  }

  void _checkLocation() async {
    final res = await LocationService.checkOfficeGeofence();
    if (mounted) {
      setState(() {
        _isInside = res.isInside;
        _distance = res.distanceMeters;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final emp = AuthService.currentEmployee;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Geofence Status Banner (PDF Page 7: 200m office location requirement)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isInside ? AppColors.success.withAlpha(25) : AppColors.danger.withAlpha(25),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isInside ? AppColors.success.withAlpha(120) : AppColors.danger.withAlpha(120),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: _isInside ? AppColors.success : AppColors.danger,
                  radius: 20,
                  child: Icon(
                    _isInside ? Icons.verified_user_rounded : Icons.location_off_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isInside ? 'Office Geofence Active (Within 200m)' : 'Outside Office Geofence',
                        style: TextStyle(
                          color: _isInside ? AppColors.success : AppColors.danger,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _isInside
                            ? 'Logged in at ${OfficeLocation.address} (${_distance.toStringAsFixed(0)}m)'
                            : 'You are ${_distance.toStringAsFixed(0)}m from office. Inside Sales operations require office premises.',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
                  tooltip: 'Recheck Location',
                  onPressed: _checkLocation,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Greeting
          Text(
            'Welcome, ${emp?.name ?? "Sales Associate"}',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Here is your lead calling and visit assignment summary for today.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),

          // KPI Stats Cards
          StreamBuilder<List<Customer>>(
            stream: DatabaseService.getCustomersStream(),
            builder: (context, snapshot) {
              final customers = snapshot.data ?? [];
              final totalAssigned = customers.length;
              final interestedCount = customers.where((c) => c.status == CustomerStatus.interested).length;
              final scheduledCount = customers.where((c) => c.status == CustomerStatus.visitScheduled).length;

              return Row(
                children: [
                  Expanded(
                    child: MetricCard(
                      title: 'Calls to Make',
                      value: '$totalAssigned',
                      icon: Icons.phone_in_talk_rounded,
                      accentColor: AppColors.primary,
                      onTap: widget.onNavigateToCalls,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: MetricCard(
                      title: 'Interested',
                      value: '$interestedCount',
                      icon: Icons.thumb_up_alt_rounded,
                      accentColor: AppColors.success,
                      onTap: widget.onNavigateToInterested,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: MetricCard(
                      title: 'Site Visits',
                      value: '$scheduledCount',
                      icon: Icons.calendar_month_rounded,
                      accentColor: AppColors.secondary,
                      onTap: widget.onNavigateToInterested,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Company Broadcast Updates Banner (PDF Page 1: Admin one-click broadcast message)
          const Text(
            'Company Announcements',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<BroadcastMessage>>(
            stream: DatabaseService.getBroadcastStream(),
            builder: (context, snapshot) {
              final msgs = snapshot.data ?? [];
              if (msgs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.notifications_none_rounded, color: AppColors.textMuted),
                      SizedBox(width: 12),
                      Text('No new announcements today.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                );
              }

              final latest = msgs.first;
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppColors.cardGradient,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withAlpha(100)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.campaign_rounded, color: AppColors.primaryLight, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          latest.title,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      latest.message,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
