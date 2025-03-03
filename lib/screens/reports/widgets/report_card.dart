// lib/screens/reports/widgets/report_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/date_formatter.dart';
import '../../../models/report_model.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common/app_card.dart';

class ReportCard extends StatelessWidget {
  final Report report;
  final VoidCallback? onTap;
  final VoidCallback? onExport;
  final VoidCallback? onDelete;

  const ReportCard({
    Key? key,
    required this.report,
    this.onTap,
    this.onExport,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Report header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReportTypeIndicator(report.reportType),
                const SizedBox(width: AppSpacing.small),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${report.reportType.toUpperCase()} REPORT',
                        style: AppTextStyles.subtitle,
                      ),
                      Text(
                        DateFormatter.formatRange(report.startDate, report.endDate),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getSuccessRateColor(report.successRate).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                  ),
                  child: Text(
                    '${report.successRate}%',
                    style: TextStyle(
                      color: _getSuccessRateColor(report.successRate),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.small),

            // Report details
            Row(
              children: [
                _buildMetricItem(
                  icon: Icons.search,
                  label: 'Scans',
                  value: report.totalScans.toString(),
                ),
                _buildMetricItem(
                  icon: Icons.warning,
                  label: 'Issues',
                  value: report.issuesCount.toString(),
                  valueColor: report.issuesCount > 0 ? AppColors.error : null,
                ),
                _buildMetricItem(
                  icon: Icons.calendar_today,
                  label: 'Created',
                  value: DateFormat('MMM d').format(report.createdAt),
                ),
              ],
            ),

            // Divider and actions
            if (onExport != null || onDelete != null) ...[
              const SizedBox(height: AppSpacing.small),
              const Divider(),
              const SizedBox(height: AppSpacing.small),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onExport != null)
                    _buildActionButton(
                      icon: Icons.download,
                      label: 'Export',
                      onTap: onExport!,
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
      ),
    );
  }

  Widget _buildReportTypeIndicator(String reportType) {
    final IconData icon;
    final String letter;

    switch (reportType.toLowerCase()) {
      case 'daily':
        icon = Icons.today;
        letter = 'D';
        break;
      case 'weekly':
        icon = Icons.date_range;
        letter = 'W';
        break;
      case 'monthly':
        icon = Icons.calendar_month;
        letter = 'M';
        break;
      case 'custom':
        icon = Icons.calendar_today;
        letter = 'C';
        break;
      default:
        icon = Icons.description;
        letter = 'R';
    }

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              icon,
              color: AppColors.primary,
              size: 24,
            ),
            Text(
              letter,
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Expanded(
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.textSecondary,
            size: 16,
          ),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
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
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.small,
          vertical: 4,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: color ?? AppColors.primary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color ?? AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSuccessRateColor(double rate) {
    if (rate >= 90) return AppColors.success;
    if (rate >= 70) return AppColors.info;
    if (rate >= 50) return AppColors.warning;
    return AppColors.error;
  }
}