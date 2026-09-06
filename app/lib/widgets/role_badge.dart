import 'package:flutter/material.dart';
import '../models/employee.dart';

class RoleBadge extends StatelessWidget {
  final AppRole role;

  const RoleBadge({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: role.color.withAlpha(35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: role.color.withAlpha(120), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(role.icon, size: 13, color: role.color),
          const SizedBox(width: 5),
          Text(
            role.label,
            style: TextStyle(
              color: role.color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}
