import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../config/app_theme.dart';
import '../../models/attendance.dart';
import '../../services/database_service.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/skeleton_shimmer.dart';

class AttendanceTab extends StatefulWidget {
  const AttendanceTab({super.key});

  @override
  State<AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends State<AttendanceTab> {
  bool? _statusFilter; // null = all, true = approved, false = rejected
  bool _showChart = true;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Attendance>>(
      stream: DatabaseService.getAttendanceStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 4,
            itemBuilder: (context, index) => const SkeletonListTile(),
          );
        }

        final allLogs = snapshot.data ?? [];

        final approvedCount = allLogs.where((l) => l.loginAllowed).length;
        final rejectedCount = allLogs.where((l) => !l.loginAllowed).length;

        final filteredLogs = allLogs.where((l) {
          if (_statusFilter == null) return true;
          return l.loginAllowed == _statusFilter;
        }).toList();

        final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                children: [
                  // Verification Bar Chart Card
                  if (allLogs.isNotEmpty) ...[
                    _buildChartCard(approvedCount, rejectedCount),
                    const SizedBox(height: 12),
                  ],

                  // Filter Chips
                  Row(
                    children: [
                      _filterChip('All (${allLogs.length})', null),
                      const SizedBox(width: 8),
                      _filterChip('Approved ($approvedCount)', true, color: AppColors.success),
                      const SizedBox(width: 8),
                      _filterChip('Geofence Failed ($rejectedCount)', false, color: AppColors.danger),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: filteredLogs.isEmpty
                  ? EmptyStateWidget(
                      icon: Icons.fact_check_rounded,
                      title: 'No Attendance Records',
                      message: _statusFilter != null
                          ? 'No attendance records matching the selected filter.'
                          : 'No attendance records logged yet today.',
                      actionLabel: _statusFilter != null ? 'Clear Filter' : null,
                      onAction: () => setState(() => _statusFilter = null),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: filteredLogs.length,
                      itemBuilder: (context, index) {
                        final item = filteredLogs[index];
                        final isApproved = item.loginAllowed;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: CardStyles.secondary(borderRadius: 14).copyWith(
                            border: Border.all(
                              color: isApproved
                                  ? AppColors.surfaceBorder
                                  : AppColors.danger.withAlpha(80),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: isApproved
                                      ? AppColors.success.withAlpha(25)
                                      : AppColors.danger.withAlpha(25),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isApproved
                                        ? AppColors.success.withAlpha(90)
                                        : AppColors.danger.withAlpha(90),
                                  ),
                                ),
                                child: Icon(
                                  isApproved
                                      ? Icons.verified_user_rounded
                                      : Icons.gpp_bad_rounded,
                                  color: isApproved
                                      ? AppColors.success
                                      : AppColors.danger,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.employeeName ??
                                                item.employeeEmail ??
                                                'Staff ID: ${item.employeeId}',
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textPrimary,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isApproved
                                                ? AppColors.success.withAlpha(25)
                                                : AppColors.danger.withAlpha(25),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            isApproved ? 'ON-SITE VERIFIED' : 'GEOFENCE REJECTED',
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.3,
                                              color: isApproved
                                                  ? AppColors.success
                                                  : AppColors.danger,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.login_rounded,
                                          size: 13,
                                          color: AppColors.textSecondary,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          'Login: ${dateFormat.format(item.loginAt)}',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (item.failureReason != null && !isApproved) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.warning_amber_rounded,
                                            size: 13,
                                            color: AppColors.danger,
                                          ),
                                          const SizedBox(width: 5),
                                          Expanded(
                                            child: Text(
                                              'Reason: ${item.failureReason}',
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                color: AppColors.danger,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    const SizedBox(height: 4),
                                    if (item.logoutAt != null)
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.logout_rounded,
                                            size: 13,
                                            color: AppColors.textMuted,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            'Logout: ${dateFormat.format(item.logoutAt!)} (${item.workingDuration.inHours}h ${item.workingDuration.inMinutes % 60}m)',
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                        ],
                                      )
                                    else
                                      Row(
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: AppColors.success,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Currently Active in Office',
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              color: AppColors.success,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChartCard(int approved, int rejected) {
    final total = approved + rejected;
    final approvalRate = total > 0 ? ((approved / total) * 100).round() : 0;
    final maxY = (max(approved, rejected) * 1.3).toDouble().clamp(4.0, 1000.0);

    return Container(
      decoration: CardStyles.primary(borderRadius: 16),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _showChart = !_showChart),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.bar_chart_rounded,
                    size: 18,
                    color: AppColors.primaryLight,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Geofence Compliance ($approvalRate% Approved)',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _showChart
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_showChart) ...[
            const Divider(height: 1, color: AppColors.surfaceBorder),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  // Bar Chart
                  SizedBox(
                    width: 140,
                    height: 85,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: maxY,
                        barTouchData: BarTouchData(enabled: true),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final text = value.toInt() == 0 ? 'Approved' : 'Rejected';
                                final color = value.toInt() == 0
                                    ? AppColors.success
                                    : AppColors.danger;
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    text,
                                    style: GoogleFonts.inter(
                                      color: color,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        barGroups: [
                          BarChartGroupData(
                            x: 0,
                            barRods: [
                              BarChartRodData(
                                toY: approved.toDouble(),
                                color: AppColors.success,
                                width: 22,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                              ),
                            ],
                          ),
                          BarChartGroupData(
                            x: 1,
                            barRods: [
                              BarChartRodData(
                                toY: rejected.toDouble(),
                                color: AppColors.danger,
                                width: 22,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Breakdown Stats
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.success,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'On-Site Approved: ',
                              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                            ),
                            Text(
                              '$approved',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.danger,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Geofence Failed: ',
                              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                            ),
                            Text(
                              '$rejected',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.danger,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Office Geofence Radius: 50m',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool? filterValue, {Color? color}) {
    final isSelected = _statusFilter == filterValue;
    final activeColor = color ?? AppColors.primary;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _statusFilter = filterValue),
      selectedColor: activeColor.withAlpha(40),
      backgroundColor: AppColors.surfaceLight,
      labelStyle: GoogleFonts.inter(
        color: isSelected ? activeColor : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        fontSize: 12,
      ),
      side: BorderSide(
        color: isSelected ? activeColor : AppColors.surfaceBorder,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}
