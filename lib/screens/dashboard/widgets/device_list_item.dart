// lib/screens/dashboard/widgets/device_list_item.dart
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../models/device_model.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/security/risk_level_badge.dart';
import '../../../widgets/security/status_badge.dart';

class DeviceListItem extends StatelessWidget {
  final Device device;
  final VoidCallback? onTap;
  final VoidCallback? onScan;
  final bool showActions;

  const DeviceListItem({
    Key? key,
    required this.device,
    this.onTap,
    this.onScan,
    this.showActions = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.medium,
        vertical: AppSpacing.small,
      ),
      margin: const EdgeInsets.only(bottom: AppSpacing.small),
      child: Column(
        children: [
          // Main device info row
          Row(
            children: [
              // Device icon with risk level
              _buildDeviceIcon(context),
              const SizedBox(width: AppSpacing.medium),

              // Device name and details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            device.deviceName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.small),
                        StatusBadge.fromDeviceStatus(device.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      device.deviceType ?? 'Unknown Device Type',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 16,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${device.openVulnerabilities} vulnerabilities',
                          style: TextStyle(
                            color: device.openVulnerabilities > 0
                                ? Colors.amber
                                : Colors.grey[600],
                            fontSize: 12,
                            fontWeight: device.openVulnerabilities > 0
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Security score as circular indicator
              _buildSecurityScoreIndicator(),
            ],
          ),

          // Optional actions row
          if (showActions)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.small),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onScan,
                    icon: const Icon(Icons.security, size: 16),
                    label: const Text('Scan Now'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.small,
                        vertical: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDeviceIcon(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getDeviceIcon(device.deviceType),
            color: AppColors.primary,
            size: 24,
          ),
        ),
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: RiskLevelBadge(
            riskLevel: device.riskLevel,
            showLabel: false,
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityScoreIndicator() {
    final scoreColor = _getScoreColor(device.securityScore);

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: scoreColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          device.securityScore.round().toString(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: scoreColor,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  IconData _getDeviceIcon(String? deviceType) {
    if (deviceType == null) return Icons.devices;

    switch (deviceType.toLowerCase()) {
      case 'camera':
      case 'smart_camera':
        return Icons.videocam;
      case 'thermostat':
        return Icons.thermostat;
      case 'smart_lock':
      case 'lock':
        return Icons.lock;
      case 'speaker':
      case 'smart_speaker':
        return Icons.speaker;
      case 'light':
      case 'smart_light':
        return Icons.lightbulb;
      case 'router':
      case 'gateway':
        return Icons.router;
      case 'tv':
      case 'smart_tv':
        return Icons.tv;
      case 'fridge':
      case 'refrigerator':
        return Icons.kitchen;
      case 'plug':
      case 'smart_plug':
        return Icons.power;
      default:
        return Icons.devices;
    }
  }

  Color _getScoreColor(double score) {
    if (score >= 90) return AppColors.riskLow;
    if (score >= 70) return AppColors.riskMedium;
    if (score >= 50) return AppColors.riskHigh;
    return AppColors.riskCritical;
  }
}