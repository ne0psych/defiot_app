// lib/screens/reports/report_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../models/report_model.dart';
import '../../providers/report_provider.dart';
import '../../services/report_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/loading_indicator.dart';
import 'report_details_screen.dart';
import 'widgets/report_card.dart';
import 'widgets/security_trend_chart.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({Key? key}) : super(key: key);

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  ReportType _selectedType = ReportType.daily;
  DateTime _selectedDate = DateTime.now();
  String _selectedFormat = 'PDF';
  bool _isGeneratingReport = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchReports() async {
    final reportProvider = Provider.of<ReportProvider>(context, listen: false);
    await reportProvider.fetchReports(
      reportType: _selectedType,
    );
  }

  Future<void> _refreshReports() async {
    final reportProvider = Provider.of<ReportProvider>(context, listen: false);
    await reportProvider.fetchReports(
      reportType: _selectedType,
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.onPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });

      // Generate report for selected date
      _generateReportForDate(picked);
    }
  }

  Future<void> _generateReportForDate(DateTime date) async {
    final reportProvider = Provider.of<ReportProvider>(context, listen: false);

    setState(() {
      _isGeneratingReport = true;
    });

    try {
      final report = await reportProvider.generateReport(
        reportType: _selectedType,
        startDate: date,
        endDate: date.add(const Duration(days: 1)),
      );

      if (report != null && mounted) {
        _navigateToReportDetails(report);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to generate report: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingReport = false;
        });
      }
    }
  }

  void _toggleReportType(ReportType type) {
    if (_selectedType != type) {
      setState(() {
        _selectedType = type;
      });
      _refreshReports();
    }
  }

  void _navigateToReportDetails(Report report) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportDetailsScreen(report: report),
      ),
    );
  }

  Future<void> _generateNewReport() async {
    // Show report generation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Generate New Report', style: AppTextStyles.title),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Report Type', style: AppTextStyles.subtitle),
              const SizedBox(height: AppSpacing.small),
              DropdownButtonFormField<ReportType>(
                value: _selectedType,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.small),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium),
                ),
                items: const [
                  DropdownMenuItem(value: ReportType.daily, child: Text('Daily Report')),
                  DropdownMenuItem(value: ReportType.weekly, child: Text('Weekly Report')),
                  DropdownMenuItem(value: ReportType.monthly, child: Text('Monthly Report')),
                  DropdownMenuItem(value: ReportType.custom, child: Text('Custom Report')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => _selectedType = value);
                  }
                },
              ),

              const SizedBox(height: AppSpacing.medium),
              Text('Date Range', style: AppTextStyles.subtitle),
              const SizedBox(height: AppSpacing.small),

              // Date Range Selector
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setDialogState(() => _selectedDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.small),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(AppRadius.small),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('yyyy-MM-dd').format(_selectedDate),
                              style: AppTextStyles.body,
                            ),
                            Icon(Icons.calendar_today, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.medium),
              Text('Report Format', style: AppTextStyles.subtitle),
              const SizedBox(height: AppSpacing.small),
              DropdownButtonFormField<String>(
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
                    setDialogState(() => _selectedFormat = value);
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          AppButton(
            label: 'Generate',
            onPressed: () {
              Navigator.pop(context);
              _generateReport();
            },
            buttonType: AppButtonType.primary,
          ),
        ],
      ),
    );
  }

  Future<void> _generateReport() async {
    final reportProvider = Provider.of<ReportProvider>(context, listen: false);

    setState(() {
      _isGeneratingReport = true;
    });

    try {
      // Calculate date range based on report type
      DateTime startDate = _selectedDate;
      DateTime endDate = _selectedDate;

      switch (_selectedType) {
        case ReportType.daily:
          endDate = startDate.add(const Duration(days: 1));
          break;
        case ReportType.weekly:
        // Set start date to beginning of week
          startDate = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
          endDate = startDate.add(const Duration(days: 7));
          break;
        case ReportType.monthly:
        // Set start date to beginning of month
          startDate = DateTime(_selectedDate.year, _selectedDate.month, 1);
          // Set end date to beginning of next month
          endDate = (_selectedDate.month < 12)
              ? DateTime(_selectedDate.year, _selectedDate.month + 1, 1)
              : DateTime(_selectedDate.year + 1, 1, 1);
          break;
        case ReportType.custom:
        // Custom already uses selected date
          endDate = startDate.add(const Duration(days: 1));
          break;
      }

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LoadingIndicator(),
              SizedBox(height: AppSpacing.medium),
              Text('Generating report...'),
            ],
          ),
        ),
      );

      final report = await reportProvider.generateReport(
        reportType: _selectedType,
        startDate: startDate,
        endDate: endDate,
      );

      // Close the loading dialog
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (report != null && mounted) {
        _showSuccessSnackBar('Report generated successfully');
        _navigateToReportDetails(report);
      } else {
        _showErrorSnackBar('Failed to generate report');
      }
    } catch (e) {
      // Close the loading dialog if still showing
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        _showErrorSnackBar('Error generating report: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingReport = false;
        });
      }
    }
  }

  Future<void> _exportReport(Report report) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LoadingIndicator(),
              SizedBox(height: AppSpacing.medium),
              Text('Exporting report...'),
            ],
          ),
        ),
      );

      // Get provider
      final provider = context.read<ReportProvider>();

      // Export the report
      await provider.exportReport(
        report.reportId,
        format: _selectedFormat.toLowerCase(),
      );

      // Close the loading dialog
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // Show success message
      _showSuccessSnackBar('Report exported successfully');
    } catch (e) {
      // Close the loading dialog if still showing
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        _showErrorSnackBar('Failed to export report: $e');
      }
    }
  }

  Future<void> _deleteReport(Report report) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Report', style: AppTextStyles.title),
        content: Text(
          'Are you sure you want to delete this report? This action cannot be undone.',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          AppButton(
            label: 'Delete',
            onPressed: () => Navigator.of(context).pop(true),
            buttonType: AppButtonType.error,
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final provider = context.read<ReportProvider>();
        await provider.deleteReport(report.reportId);

        // Refresh reports after delete
        await _refreshReports();
        _showSuccessSnackBar('Report deleted successfully');
      } catch (e) {
        _showErrorSnackBar('Failed to delete report: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.onError),
            const SizedBox(width: AppSpacing.small),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.small)),
        margin: const EdgeInsets.all(AppSpacing.small),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.onSuccess),
            const SizedBox(width: AppSpacing.small),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.small)),
        margin: const EdgeInsets.all(AppSpacing.small),
      ),
    );
  }

  List<Report> _filterReports(List<Report> reports) {
    if (_searchQuery.isEmpty) return reports;

    return reports.where((report) {
      // Search in report type, ID, or date
      final reportType = report.reportType.toLowerCase();
      final reportId = report.reportId.toString();
      final date = DateFormat('yyyy-MM-dd').format(report.startDate);

      return reportType.contains(_searchQuery.toLowerCase()) ||
          reportId.contains(_searchQuery) ||
          date.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'REPORTS',
          style: AppTextStyles.title.copyWith(color: AppColors.onPrimary),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
            tooltip: 'Select Date',
          ),
        ],
      ),
      body: Container(
        color: AppColors.background,
        child: Column(
          children: [
            // Search Header
            Container(
              padding: const EdgeInsets.all(AppSpacing.medium),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(AppRadius.large),
                  bottomRight: Radius.circular(AppRadius.large),
                ),
              ),
              child: Column(
                children: [
                  // Search bar
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'Search reports...',
                        prefixIcon: Icon(Icons.search, color: AppColors.primary),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.medium),

                  // Report type toggles
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildReportTypeToggle('Day', ReportType.daily),
                      _buildReportTypeToggle('Week', ReportType.weekly),
                      _buildReportTypeToggle('Month', ReportType.monthly),
                    ],
                  ),
                ],
              ),
            ),

            // Reports List
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshReports,
                child: Consumer<ReportProvider>(
                  builder: (context, reportProvider, child) {
                    if (reportProvider.isLoading) {
                      return const Center(child: LoadingIndicator());
                    }

                    if (reportProvider.error != null) {
                      return _buildErrorView(reportProvider);
                    }

                    final reports = _filterReports(reportProvider.reports);

                    if (reports.isEmpty) {
                      return _buildEmptyView();
                    }

                    return ListView(
                      padding: const EdgeInsets.all(AppSpacing.medium),
                      children: [
                        // Security Trend Chart
                        const SecurityTrendChart(),
                        const SizedBox(height: AppSpacing.medium),

                        // Reports Section
                        Text(
                          'Recent Reports',
                          style: AppTextStyles.title,
                        ),
                        const SizedBox(height: AppSpacing.small),

                        // Reports List
                        ...reports.map((report) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.medium),
                          child: ReportCard(
                            report: report,
                            onTap: () => _navigateToReportDetails(report),
                            onExport: () => _exportReport(report),
                            onDelete: () => _deleteReport(report),
                          ),
                        )).toList(),
                      ],
                    );
                  },
                ),
              ),
            ),

            // Weekly Summary (if available)
            _buildWeeklySummary(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _generateNewReport,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
        tooltip: 'Generate New Report',
      ),
    );
  }

  Widget _buildReportTypeToggle(String label, ReportType type) {
    final isSelected = _selectedType == type;

    return InkWell(
      onTap: () => _toggleReportType(type),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.medium,
          vertical: AppSpacing.small,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.surface,
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.surface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.large),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.description_outlined,
                size: 64,
                color: AppColors.textDisabled,
              ),
              const SizedBox(height: AppSpacing.medium),
              Text(
                'No reports found',
                style: AppTextStyles.title,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.small),
              Text(
                'Generate a new report to analyze your security status',
                style: TextStyle(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.large),
              AppButton(
                label: 'Generate Report',
                icon: Icons.add,
                onPressed: _generateNewReport,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView(ReportProvider provider) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.large),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error,
              ),
              const SizedBox(height: AppSpacing.medium),
              Text(
                'Error loading reports',
                style: AppTextStyles.title,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.small),
              Text(
                provider.error ?? 'An unknown error occurred',
                style: TextStyle(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.large),
              AppButton(
                label: 'Retry',
                icon: Icons.refresh,
                onPressed: _refreshReports,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklySummary() {
    return Consumer<ReportProvider>(
      builder: (context, reportProvider, _) {
        if (reportProvider.reports.isEmpty) return const SizedBox.shrink();

        // Calculate summary metrics
        int totalScans = 0;
        double avgSuccessRate = 0.0;
        int totalIssues = 0;

        for (var report in reportProvider.reports) {
          totalScans += report.totalScans;
          totalIssues += report.issuesCount;
        }

        avgSuccessRate = reportProvider.reports.isNotEmpty
            ? (reportProvider.reports.fold(0.0, (sum, report) => sum + report.successRate)) /
            reportProvider.reports.length
            : 0.0;

        return Container(
          padding: const EdgeInsets.all(AppSpacing.medium),
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Weekly Summary',
                style: AppTextStyles.subtitle,
              ),
              const SizedBox(height: AppSpacing.small),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      title: 'Total Scans',
                      value: totalScans.toString(),
                      icon: Icons.search,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.small),
                  Expanded(
                    child: _buildSummaryCard(
                      title: 'Success Rate',
                      value: '${avgSuccessRate.toStringAsFixed(1)}%',
                      icon: Icons.check_circle,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.small),
                  Expanded(
                    child: _buildSummaryCard(
                      title: 'Issues',
                      value: totalIssues.toString(),
                      icon: Icons.warning,
                      color: totalIssues > 0 ? AppColors.warning : AppColors.success,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.small),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}