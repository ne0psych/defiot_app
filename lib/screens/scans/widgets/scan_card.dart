// lib/screens/scans/widgets/scan_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/scan_model.dart';
import '../../../theme/app_theme.dart';

class ScanCard extends StatelessWidget {
  final Scan scan;
  final VoidCallback? onTap;
  final VoidCallback? onExport;
  final VoidCallback? onRescan;
  final VoidCallback? onDelete;

  const ScanCard({
    Key? key,
    required this.scan,
    this.onTap,
    this.onExport,
    this.onRescan,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Scan header
          Row(
            children: [
              _buildRiskLevelIndicator(scan.riskLevel),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scan #${scan.scanId}',
                      style: AppTextStyles.subtitle,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildStatusChip(scan.status),
                        if (scan.scanType.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            '${scan.scanType.toCapitalized()} Scan',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (scan.securityScore != null)
                _buildSecurityScore(scan.securityScore!),
            ],
          ),
          const SizedBox(height: AppSpacing.small),

          // Scan timestamp
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                _formatDateTime(scan.createdAt),
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),

          // Vulnerabilities summary
          Row(
            children: [
              Icon(
                scan.vulnerabilitiesFound > 0 ? Icons.warning : Icons.check_circle,
                size: 14,
                color: scan.vulnerabilitiesFound > 0 ? AppColors.error : AppColors.success,
              ),
              const SizedBox(width: 4),
              Text(
                '${scan.vulnerabilitiesFound} ${scan.vulnerabilitiesFound == 1 ? 'vulnerability' : 'vulnerabilities'} found',
                style: TextStyle(
                  color: scan.vulnerabilitiesFound > 0 ? AppColors.error : AppColors.success,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),

          // Divider
          if (onExport != null || onRescan != null || onDelete != null) ...[
            const SizedBox(height: AppSpacing.small),
            const Divider(),
            const SizedBox(height: AppSpacing.small),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (onExport != null)
                  _buildActionButton(
                    icon: Icons.download,
                    label: 'Export',
                    onTap: onExport!,
                  ),
                if (onRescan != null)
                  _buildActionButton(
                    icon: Icons.refresh,
                    label: 'Rescan',
                    onTap: onRescan!,
                  ),
                if (onDelete != null)
                  _buildActionButton(
                    icon: Icons.delete,
                    label: 'Delete',
                    onTap: onDelete!,
                    color: AppColors.error,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRiskLevelIndicator(RiskLevel riskLevel) {
    final color = _getRiskLevelColor(riskLevel);

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          _getRiskLevelIcon(riskLevel),
          color: color,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildStatusChip(ScanStatus status) {
    Color color;
    IconData icon;

    switch (status) {
      case ScanStatus.completed:
        color = AppColors.success;
        icon = Icons.check_circle;
        break;
      case ScanStatus.inProgress:
        color = AppColors.info;
        icon = Icons.sync;
        break;
      case ScanStatus.failed:
        color = AppColors.error;
        icon = Icons.error;
        break;
      case ScanStatus.pending:
        color = AppColors.warning;
        icon = Icons.hourglass_empty;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            status.toString().split('.').last.toCapitalized(),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityScore(double score) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _getScoreColor(score).withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          score.toInt().toString(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _getScoreColor(score),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.small),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color ?? AppColors.primary, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color ?? AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRiskLevelColor(RiskLevel riskLevel) {
    switch (riskLevel) {
      case RiskLevel.critical:
        return AppColors.riskCritical;
      case RiskLevel.high:
        return AppColors.riskHigh;
      case RiskLevel.medium:
        return AppColors.riskMedium;
      case RiskLevel.low:
        return AppColors.riskLow;
    }
  }

  IconData _getRiskLevelIcon(RiskLevel riskLevel) {
    switch (riskLevel) {
      case RiskLevel.critical:
        return Icons.dangerous;
      case RiskLevel.high:
        return Icons.error;
      case RiskLevel.medium:
        return Icons.warning;
      case RiskLevel.low:
        return Icons.check_circle;
    }
  }

  Color _getScoreColor(double score) {
    if (score >= 90) return AppColors.success;
    if (score >= 70) return AppColors.info;
    if (score >= 50) return AppColors.warning;
    return AppColors.error;
  }

  String _formatDateTime(DateTime date) {
    return DateFormat('MMM d, y HH:mm').format(date);
  }
}

// Extension for string capitalization
extension StringCasingExtension on String {
  String toCapitalized() => length > 0
      ? '${this[0].toUpperCase()}${substring(1)}'
      : '';

  String toTitleCase() => replaceAll(RegExp(' +'), ' ')
      .split(' ')
      .map((str) => str.toCapitalized())
      .join(' ');
}