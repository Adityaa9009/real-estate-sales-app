import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../config/app_theme.dart';

class SkeletonShimmer extends StatelessWidget {
  final Widget child;

  const SkeletonShimmer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      period: const Duration(milliseconds: 1500),
      child: child,
    );
  }
}

class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.shimmerBase,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class SkeletonListTile extends StatelessWidget {
  const SkeletonListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonBox(width: 140, height: 16, borderRadius: 6),
                SkeletonBox(width: 70, height: 22, borderRadius: 12),
              ],
            ),
            SizedBox(height: 12),
            SkeletonBox(width: 180, height: 12, borderRadius: 4),
            SizedBox(height: 8),
            SkeletonBox(width: double.infinity, height: 12, borderRadius: 4),
          ],
        ),
      ),
    );
  }
}

class SkeletonMetricGrid extends StatelessWidget {
  final int count;

  const SkeletonMetricGrid({super.key, this.count = 3});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: Row(
        children: List.generate(count, (index) {
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < count - 1 ? 10 : 0),
              padding: const EdgeInsets.all(16),
              height: 110,
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SkeletonBox(width: 32, height: 32, borderRadius: 10),
                  SkeletonBox(width: 50, height: 20, borderRadius: 4),
                  SkeletonBox(width: 80, height: 12, borderRadius: 4),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
