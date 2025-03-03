// lib/screens/devices/widgets/device_card.dart
import 'package:flutter/material.dart';
import '../../../models/device_model.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/security/risk_level_badge.dart';
import '../../../widgets/security/status_badge.dart';

class DeviceCard extends StatelessWidget {
  final Device device;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onScan;
  final bool selectable;
  final bool isSelected;
  final ValueChanged<bool>? onSelectChanged;

  const DeviceCard({
    Key? key,
    required this.device,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onScan,
    this.selectable = false,
    this.isSelected = false,
    this.onSelectChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isOnline = device.status == DeviceStatus.active;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.large),
        side: isSelected
            ? BorderSide(color: AppColors.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.large),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.medium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildDeviceIcon(isOnline),
                  const SizedBox(width: AppSpacing.medium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.deviceName,
                          style: AppTextStyles.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          device.deviceType ?? 'Unknown Device',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (selectable)
                    Checkbox(
                      value: isSelected,
                      onChanged: (value) {
                        if (onSelectChanged != null && value != null) {
                          onSelectChanged!(value);
                        }
                      },
                      activeColor: AppColors.primary,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.medium),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            StatusBadge.fromDeviceStatus(device.status),
                            const SizedBox(width: AppSpacing.small),
                            RiskLevelBadge(riskLevel: device.riskLevel),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          device.ipAddress.isNotEmpty ? device.ipAddress : 'No IP Address',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  _buildActionButtons(context),
                ],
              ),
              if (device.openVulnerabilities > 0) ...[
                const SizedBox(height: AppSpacing.small),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.small,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.small),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.error,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${device.openVulnerabilities} ${device.openVulnerabilities == 1 ? 'vulnerability' : 'vulnerabilities'}',
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceIcon(bool isOnline) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          child: Icon(
            Icons.devices,
            color: AppColors.primary,
            size: 28,
          ),
        ),
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: isOnline ? AppColors.success : AppColors.error,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Icon(
            isOnline ? Icons.check : Icons.close,
            size: 8,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onScan != null)
          IconButton(
            icon: Icon(Icons.security, color: AppColors.primary),
            onPressed: onScan,
            tooltip: 'Scan Device',
            constraints: const BoxConstraints(
              minWidth: 36,
              minHeight: 36,
            ),
            padding: EdgeInsets.zero,
          ),
        if (onEdit != null)
          IconButton(
            icon: Icon(Icons.edit, color: AppColors.secondary),
            onPressed: onEdit,
            tooltip: 'Edit Device',
            constraints: const BoxConstraints(
              minWidth: 36,
              minHeight: 36,
            ),
            padding: EdgeInsets.zero,
          ),
        if (onDelete != null)
          IconButton(
            icon: Icon(Icons.delete, color: AppColors.error),
            onPressed: onDelete,
            tooltip: 'Delete Device',
            constraints: const BoxConstraints(
              minWidth: 36,
              minHeight: 36,
            ),
            padding: EdgeInsets.zero,
          ),
      ],
    );
  }
}