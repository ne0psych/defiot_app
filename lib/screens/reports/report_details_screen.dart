// lib/screens/reports/report_details_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/utils/date_formatter.dart';
import '../../models/device_model.dart';
import '../../models/report_model.dart';
import '../../models/vulnerability_model.dart';
import '../../providers/report_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/security/risk_level_badge.dart';
import 'widgets/security_trend_chart.dart';

class ReportDetailsScreen extends StatefulWidget {
  final Report report;

  const ReportDetailsScreen({
    Key? key,
    required this.report,
  }) : super(key: key);

  @override
  State<ReportDetailsScreen> createState() => _ReportDetailsScreenState();
}

class _ReportDetailsScreenState extends State<ReportDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFormat = 'PDF';
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _exportReport() async {
    if (_isExporting) return;

    try {
      setState(() {
        _isExporting = true;
      });

      // Show format selection dialog
      final format = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Export Report', style: AppTextStyles.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select format:', style: AppTextStyles.body),
              const SizedBox(height: AppSpacing.medium),
              StatefulBuilder(
                builder: (context, setState) => DropdownButtonFormField<String>(
                  value: _selectedFormat,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.small),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'PDF', child: Text('PDF Document')),
                    DropdownMenuItem(value: 'CSV', child: Text('CSV File')),
                    DropdownMenuItem(value: 'Excel', child: Text('Excel Spreadsheet')),
                    DropdownMenuItem(value: 'JSON', child: Text('JSON File')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedFormat = value;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            AppButton(
              label: 'Export',
              onPressed: () => Navigator.of(context).pop(_selectedFormat),
              buttonType: AppButtonType.primary,
            ),
          ],
        ),
      );

      if (format == null) {
        setState(() {
          _isExporting = false;
          AppButton(
            label: issue.status == _MockIssueStatus.inProgress
                ? 'Mark Resolved'
                : 'Start Remediation',
            onPressed: () {
              // This would be implemented with real functionality in a complete app
              _showSuccessSnackBar('Status updated successfully');
            },
            buttonType: AppButtonType.secondary,
            size: AppButtonSize.small,
          ),
          ],
          ),
          ],
          ],
          ),
          ),
          );
        }

            Widget _buildIssueStatusBadge(_MockIssueStatus status) {
          late Color color;
          late String text;

          switch (status) {
            case _MockIssueStatus.open:
              color = AppColors.error;
              text = 'OPEN';
              break;
            case _MockIssueStatus.inProgress:
              color = AppColors.warning;
              text = 'IN PROGRESS';
              break;
            case _MockIssueStatus.resolved:
              color = AppColors.success;
              text = 'RESOLVED';
              break;
          }

          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.medium),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }

        Widget _buildMonthComparisonRow({
          required String month,
          required int scans,
          required int issues,
          required double success,
          bool showTrend = false,
        }) {
          final isImproving = month == 'Current' ? true : issues < (issues * 1.2).round();

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(month),
                Text(scans.toString()),
                Row(
                  children: [
                    Text(issues.toString()),
                    if (showTrend) ...[
                      const SizedBox(width: 4),
                      Icon(
                        isImproving ? Icons.arrow_downward : Icons.arrow_upward,
                        color: isImproving ? AppColors.success : AppColors.error,
                        size: 14,
                      ),
                    ],
                  ],
                ),
                Text('${success.toStringAsFixed(1)}%'),
              ],
            ),
          );
        }

        Color _getSuccessRateColor(double rate) {
          if (rate >= 90) return AppColors.success;
          if (rate >= 70) return AppColors.info;
          if (rate >= 50) return AppColors.warning;
          return AppColors.error;
        }

        Color _getSeverityColor(RiskLevel severity) {
          switch (severity) {
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

        Color _getRiskLevelColorFromString(String riskLevel) {
          switch (riskLevel.toLowerCase()) {
            case 'critical':
              return AppColors.riskCritical;
            case 'high':
              return AppColors.riskHigh;
            case 'medium':
              return AppColors.riskMedium;
            case 'low':
              return AppColors.riskLow;
            default:
              return Colors.grey;
          }
        }

        IconData _getVulnerabilityIcon(String type) {
          switch (type.toUpperCase()) {
            case 'WEAK_CREDENTIALS':
              return Icons.password;
            case 'INSECURE_PROTOCOLS':
              return Icons.security;
            case 'AUTH_BYPASS':
              return Icons.no_encryption;
            case 'FIRMWARE_ISSUES':
              return Icons.system_update;
            case 'ENCRYPTION_ISSUES':
              return Icons.lock_open;
            case 'DEFAULT_CREDENTIALS':
              return Icons.key_off;
            case 'OPEN_PORTS':
              return Icons.router;
            default:
              return Icons.help_outline;
          }
        }

        IconData _getDeviceTypeIcon(String type) {
          switch (type.toLowerCase()) {
            case 'camera':
              return Icons.videocam;
            case 'lock':
              return Icons.lock;
            case 'thermostat':
              return Icons.thermostat;
            case 'lighting':
              return Icons.lightbulb;
            default:
              return Icons.devices_other;
          }
        }

        String _formatKey(String key) {
          return key
              .replaceAll('_', ' ')
              .split(' ')
              .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
              .join(' ');
        }

        String _formatValue(dynamic value) {
          if (value is bool) {
            return value ? 'Yes' : 'No';
          } else if (value is num) {
            return value.toString();
          } else if (value is Map || value is List) {
            return const JsonEncoder.withIndent('  ').convert(value);
          }
          return value.toString();
        }
      }

// Mock classes for demonstration purposes
    class _MockDevice {
    final String name;
    final String type;
    final RiskLevel riskLevel;
    final int issues;

    _MockDevice({
    required this.name,
    required this.type,
    required this.riskLevel,
    required this.issues,
    });
    }

    enum _MockIssueStatus {
    open,
    inProgress,
    resolved,
    }

    class _MockIssue {
    final String title;
    final String description;
    final RiskLevel severity;
    final DateTime date;
    final _MockIssueStatus status;

    _MockIssue({
    required this.title,
    required this.description,
    required this.severity,
    required this.date,
    required this.status,
    });
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