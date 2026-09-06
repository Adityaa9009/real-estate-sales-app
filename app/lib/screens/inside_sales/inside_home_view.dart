import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

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
  bool _checkingLocation = false;

  @override
  void initState() {
    super.initState();
    _checkLocation();
  }

  void _checkLocation() async {
    setState(() => _checkingLocation = true);
    final res = await LocationService.checkOfficeGeofence();
    if (mounted) {
      setState(() {
        _isInside = res.isInside;
        _distance = res.distanceMeters;
        _checkingLocation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final emp = AuthService.currentEmployee;
    final todayStr = DateFormat('EEEE, MMM d, yyyy').format(DateTime.now());

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Geofence Status Banner
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _isInside
                  ? AppColors.success.withAlpha(20)
                  : AppColors.danger.withAlpha(20),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _isInside
                    ? AppColors.success.withAlpha(100)
                    : AppColors.danger.withAlpha(100),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: (_isInside ? AppColors.success : AppColors.danger).withAlpha(25),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (_isInside ? AppColors.success : AppColors.danger).withAlpha(35),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _isInside ? Icons.verified_user_rounded : Icons.location_off_rounded,
                    color: _isInside ? AppColors.success : AppColors.danger,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _isInside ? 'Office Geofence Active' : 'Outside Office Geofence',
                            style: GoogleFonts.sora(
                              color: _isInside ? AppColors.success : AppColors.danger,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: (_isInside ? AppColors.success : AppColors.danger).withAlpha(40),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _isInside ? 'APPROVED' : 'RESTRICTED',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: _isInside ? AppColors.success : AppColors.danger,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isInside
                            ? '${OfficeLocation.address} • ${_distance.toStringAsFixed(0)}m from center (≤200m required)'
                            : 'Distance: ${_distance.toStringAsFixed(0)}m. Inside Sales calling operations must occur within 200m of office.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: _checkingLocation
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryLight),
                        )
                      : const Icon(Icons.refresh_rounded, color: AppColors.textSecondary, size: 20),
                  tooltip: 'Recheck Location',
                  onPressed: _checkingLocation ? null : _checkLocation,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Greeting
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, ${emp?.name ?? "Sales Rep"}',
                    style: GoogleFonts.sora(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    todayStr,
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // KPI Stats Cards
          StreamBuilder<List<Customer>>(
            stream: DatabaseService.getCustomersStream(
              assignedInsideSalesId: FirebaseAuth.instance.currentUser?.uid,
            ),
            builder: (context, snapshot) {
              final customers = snapshot.data ?? [];
              final totalAssigned = customers.length;
              final interestedCount = customers
                  .where((c) => c.status == CustomerStatus.interested)
                  .length;
              final scheduledCount = customers
                  .where((c) => c.status == CustomerStatus.visitScheduled)
                  .length;

              return LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 600;
                  final cards = [
                    MetricCard(
                      title: 'Calls to Make',
                      value: '$totalAssigned',
                      icon: Icons.phone_in_talk_rounded,
                      accentColor: AppColors.primary,
                      onTap: widget.onNavigateToCalls,
                    ),
                    MetricCard(
                      title: 'Interested',
                      value: '$interestedCount',
                      icon: Icons.thumb_up_alt_rounded,
                      accentColor: AppColors.success,
                      onTap: widget.onNavigateToInterested,
                    ),
                    MetricCard(
                      title: 'Site Visits',
                      value: '$scheduledCount',
                      icon: Icons.calendar_month_rounded,
                      accentColor: AppColors.secondary,
                      onTap: widget.onNavigateToInterested,
                    ),
                  ];

                  if (isNarrow) {
                    return Column(
                      children: cards.map((c) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: c,
                      )).toList(),
                    );
                  }

                  return Row(
                    children: cards
                        .map((c) => Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: c,
                              ),
                            ))
                        .toList(),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 28),

          // Company Broadcast Updates Banner
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.campaign_rounded, color: AppColors.primaryLight, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Company Announcements',
                style: GoogleFonts.sora(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<BroadcastMessage>>(
            stream: DatabaseService.getBroadcastStream(),
            builder: (context, snapshot) {
              final msgs = snapshot.data ?? [];
              if (msgs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.notifications_none_rounded, color: AppColors.textMuted, size: 22),
                      const SizedBox(width: 12),
                      Text(
                        'No company-wide announcements posted today.',
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final latest = msgs.first;
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withAlpha(90)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(20),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(40),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'ADMIN BROADCAST',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryLight,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          DateFormat('MMM dd, hh:mm a').format(latest.createdAt),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      latest.title,
                      style: GoogleFonts.sora(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      latest.message,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
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
