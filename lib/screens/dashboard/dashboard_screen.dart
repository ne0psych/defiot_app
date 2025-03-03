// lib/screens/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/device_provider.dart';
import '../../providers/scan_provider.dart';
import '../../providers/report_provider.dart';
import '../../models/device_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/search_field.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/security/security_score_widget.dart';
import 'widgets/security_metrics_card.dart';
import 'widgets/device_list_item.dart';
import 'widgets/vulnerability_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isInitialized = false;
  bool _isRefreshing = false;
  Map<String, dynamic> _dashboardMetrics = {
    'scans': 0,
    'fixed': 0,
    'vulns': 0,
    'nextScan': 'N/A',
    'score': 0.0,
  };

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    if (mounted) {
      setState(() {
        _isInitialized = false;
      });
    }

    try {
      final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
      final scanProvider = Provider.of<ScanProvider>(context, listen: false);
      final reportProvider = Provider.of<ReportProvider>(context, listen: false);

      // Load data in parallel for efficiency
      await Future.wait([
        deviceProvider.loadDevices(),
        scanProvider.loadScans(limit: 50),
        reportProvider.fetchReports(reportType: ReportType.daily, limit: 10)
      ]);

      // Calculate metrics
      _calculateDashboardMetrics(deviceProvider, scanProvider, reportProvider);
    } catch (e) {
      // Error handling
    } finally {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  Future<void> _refreshDashboard() async {
    if (mounted) {
      setState(() {
        _isRefreshing = true;
      });
    }

    await _initData();

    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  void _calculateDashboardMetrics(
      DeviceProvider deviceProvider,
      ScanProvider scanProvider,
      ReportProvider reportProvider
      ) {
    if (!mounted) return;

    try {
      // Total scans
      final totalScans = scanProvider.scans.length;

      // Fixed issues
      int fixedIssues = 0;
      reportProvider.reports.forEach((report) {
        if (report.successRate > 70) {
          fixedIssues += (report.issuesCount * report.successRate / 100).round();
        }
      });

      // Current vulnerabilities
      int totalVulnerabilities = 0;
      double averageScore = 0;
      int deviceCount = 0;

      for (var device in deviceProvider.devices) {
        totalVulnerabilities += device.openVulnerabilities;
        if (device.openVulnerabilities == 0) {
          totalVulnerabilities += device.criticalIssues +
              device.highIssues +
              device.mediumIssues +
              device.lowIssues;
        }

        if (device.securityScore > 0) {
          averageScore += device.securityScore;
          deviceCount++;
        }
      }

      // Next scan time calculation
      DateTime nextScanTime = DateTime.now().add(const Duration(hours: 2));

      if (scanProvider.scans.isNotEmpty) {
        final latestScans = scanProvider.scans
            .where((s) => s.status == ScanStatus.completed)
            .toList();

        if (latestScans.isNotEmpty) {
          latestScans.sort((a, b) => b.completedAt!.compareTo(a.completedAt!));
          nextScanTime = latestScans.first.completedAt!.add(const Duration(hours: 24));

          if (nextScanTime.isBefore(DateTime.now())) {
            nextScanTime = DateTime.now().add(const Duration(hours: 2));
          }
        }
      }

      final formattedNextScan = _formatTime(nextScanTime);
      final securityScore = deviceCount > 0 ? (averageScore / deviceCount) : 0;

      setState(() {
        _dashboardMetrics = {
          'scans': totalScans,
          'fixed': fixedIssues,
          'vulns': totalVulnerabilities,
          'nextScan': formattedNextScan,
          'score': securityScore,
        };
      });
    } catch (e) {
      // Fallback metrics if calculation fails
      setState(() {
        _dashboardMetrics = {
          'scans': 0,
          'fixed': 0,
          'vulns': 0,
          'nextScan': 'N/A',
          'score': 0.0,
        };
      });
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    if (dateTime.isBefore(tomorrow)) {
      return 'Today ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (dateTime.isBefore(tomorrow.add(const Duration(days: 1)))) {
      return 'Tomorrow ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: Container(
        color: AppColors.background,
        child: Column(
          children: [
            // Search Container
            Container(
              padding: const EdgeInsets.all(AppSpacing.medium),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(AppRadius.round),
                  bottomRight: Radius.circular(AppRadius.round),
                ),
              ),
              child: SearchField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                hintText: 'Search devices, reports...',
              ),
            ),

            // Dashboard Content
            Expanded(
              child: !_isInitialized
                  ? const Center(
                child: LoadingIndicator(
                  size: LoadingSize.large,
                  message: 'Loading dashboard data...',
                ),
              )
                  : RefreshIndicator(
                onRefresh: _refreshDashboard,
                color: AppColors.primary,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.medium),
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Security Score
                      SecurityScoreWidget(
                        score: _dashboardMetrics['score'] ?? 0.0,
                        label: 'Overall Security Score',
                        showLabel: true,
                        size: 150,
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(height: AppSpacing.medium),

                      // Statistics Section
                      const SectionHeader(
                        title: 'Security Overview',
                        icon: Icons.analytics,
                      ),
                      _buildSecurityMetricsCards(),
                      const SizedBox(height: AppSpacing.medium),

                      // Vulnerability Trend Chart
                      const SectionHeader(
                        title: 'Vulnerability Trend',
                        icon: Icons.trending_up,
                      ),
                      const VulnerabilityChart(),
                      const SizedBox(height: AppSpacing.medium),

                      // Devices Section
                      _buildDevicesSection(),
                      const SizedBox(height: AppSpacing.medium),

                      // Action Buttons
                      _buildActionButtons(),
                      const SizedBox(height: AppSpacing.large),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityMetricsCards() {
    return Row(
      children: [
        Expanded(
          child: SecurityMetricsCard(
            title: 'Scans',
            value: _dashboardMetrics['scans'].toString(),
            icon: Icons.search,
            color: AppColors.info,
          ),
        ),
        const SizedBox(width: AppSpacing.small),
        Expanded(
          child: SecurityMetricsCard(
            title: 'Vulns',
            value: _dashboardMetrics['vulns'].toString(),
            icon: Icons.warning,
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: AppSpacing.small),
        Expanded(
          child: SecurityMetricsCard(
            title: 'Fixed',
            value: _dashboardMetrics['fixed'].toString(),
            icon: Icons.check_circle,
            color: AppColors.success,
          ),
        ),
      ],
    );
  }

  Widget _buildDevicesSection() {
    return Consumer<DeviceProvider>(
      builder: (context, deviceProvider, _) {
        if (deviceProvider.isLoading) {
          return const Center(
            child: LoadingIndicator(
              size: LoadingSize.medium,
              message: 'Loading devices...',
            ),
          );
        }

        if (deviceProvider.error != null) {
          return ErrorView(
            error: deviceProvider.error!,
            onRetry: () => deviceProvider.loadDevices(),
          );
        }

        // Filter devices based on search query
        final devices = deviceProvider.devices
            .where((device) =>
        _searchQuery.isEmpty ||
            device.deviceName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (device.deviceType?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
        )
            .toList();

        // Sort by risk level (critical first)
        devices.sort((a, b) => b.riskLevel.index.compareTo(a.riskLevel.index));

        if (devices.isEmpty) {
          return _buildEmptyDeviceState();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Devices',
              icon: Icons.devices,
              actionText: 'View All',
              onActionPressed: () => Navigator.pushNamed(context, '/devices'),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: devices.length > 3 ? 3 : devices.length,
              itemBuilder: (context, index) {
                return DeviceListItem(
                  device: devices[index],
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/devices/details',
                    arguments: devices[index].id,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyDeviceState() {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.devices,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: AppSpacing.medium),
            Text(
              'No devices found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.small),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try a different search query'
                  : 'Add your first IoT device to start monitoring security',
              style: TextStyle(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.medium),
            AppButton(
              text: 'Add Device',
              icon: Icons.add,
              onPressed: () => Navigator.pushNamed(context, '/devices/add'),
              type: AppButtonType.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: AppButton(
            text: 'Scan Devices',
            icon: Icons.security,
            onPressed: () => Navigator.pushNamed(context, '/scan'),
            type: AppButtonType.primary,
            fullWidth: true,
          ),
        ),
        const SizedBox(width: AppSpacing.medium),
        Expanded(
          child: AppButton(
            text: 'Reports',
            icon: Icons.assessment,
            onPressed: () => Navigator.pushNamed(context, '/reports'),
            type: AppButtonType.outlined,
            fullWidth: true,
          ),
        ),
      ],
    );
  }
}