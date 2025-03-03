// lib/widgets/security/status_badge.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/device_model.dart';

class StatusBadge extends StatelessWidget {
  final bool isOnline;
  final String? text;

  const StatusBadge({
    Key? key,
    required this.isOnline,
    this.text,
  }) : super(key: key);

  factory StatusBadge.fromDeviceStatus(DeviceStatus status) {
    return StatusBadge(
      isOnline: status == DeviceStatus.active,
      text: status == DeviceStatus.active ? 'Online' : 'Offline',
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = isOnline ? AppColors.success : AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          if (text != null) ...[
            const SizedBox(width: 4),
            Text(
              text!,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}