import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DashboardHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onAddPressed;

  const DashboardHeader({
    super.key,
    required this.title,
    this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.card,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontSize: 20),
            ),
          ),
          if (onAddPressed != null)
            IconButton(
              onPressed: onAddPressed,
              icon: const Icon(Icons.add_circle,
                  color: AppColors.accentOrange),
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }
}
