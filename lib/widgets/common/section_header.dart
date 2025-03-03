// lib/widgets/common/section_header.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final VoidCallback? onActionPressed;
  final String? actionText;
  final IconData? actionIcon;

  const SectionHeader({
    Key? key,
    required this.title,
    this.icon,
    this.onActionPressed,
    this.actionText,
    this.actionIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.medium),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: AppSpacing.small),
              ],
              Text(
                title,
                style: AppTextStyles.heading3,
              ),
            ],
          ),
          if (onActionPressed != null) ...[
            TextButton.icon(
              onPressed: onActionPressed,
              icon: Icon(actionIcon ?? Icons.arrow_forward),
              label: Text(actionText ?? 'See All'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.small,
                  vertical: AppSpacing.tiny,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}