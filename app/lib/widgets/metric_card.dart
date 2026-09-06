import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../config/app_theme.dart';

class MetricCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onTap;
  final bool isPrimary;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
    this.onTap,
    this.isPrimary = false,
  });

  @override
  State<MetricCard> createState() => _MetricCardState();
}

class _MetricCardState extends State<MetricCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final borderRadius = widget.isPrimary ? 18.0 : 16.0;

    final decoration = widget.isPrimary
        ? CardStyles.primary(
            glowColor: widget.accentColor,
            borderRadius: borderRadius,
            gradient: LinearGradient(
              colors: [
                widget.accentColor.withAlpha(40),
                AppColors.surfaceCard,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          )
        : CardStyles.secondary(
            borderRadius: borderRadius,
          );

    return AnimatedScale(
      scale: _isPressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (highlighted) {
            setState(() => _isPressed = highlighted);
          },
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: widget.accentColor.withAlpha(30),
          highlightColor: widget.accentColor.withAlpha(15),
          child: Container(
            padding: EdgeInsets.all(widget.isPrimary ? 18 : 15),
            decoration: decoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.all(widget.isPrimary ? 10 : 8),
                      decoration: BoxDecoration(
                        color: widget.accentColor.withAlpha(widget.isPrimary ? 45 : 30),
                        borderRadius: BorderRadius.circular(widget.isPrimary ? 14 : 11),
                        border: Border.all(
                          color: widget.accentColor.withAlpha(widget.isPrimary ? 120 : 80),
                          width: widget.isPrimary ? 1.4 : 1.0,
                        ),
                      ),
                      child: Icon(
                        widget.icon,
                        color: widget.accentColor,
                        size: widget.isPrimary ? 22 : 18,
                      ),
                    ),
                    if (widget.onTap != null)
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 12,
                        color: widget.accentColor.withAlpha(widget.isPrimary ? 220 : 160),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  widget.value,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: widget.isPrimary ? 26 : 21,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: widget.isPrimary ? FontWeight.w600 : FontWeight.w500,
                    fontSize: widget.isPrimary ? 12 : 11,
                    color: widget.isPrimary ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.1, end: 0);
  }
}

