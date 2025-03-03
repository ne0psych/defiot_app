// lib/screens/scans/scan_results_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/device_model.dart';
import '../../models/scan_model.dart';
import '../../models/vulnerability_model.dart';
import '../../providers/device_provider.dart';
import '../../providers/scan_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/security/risk_level_badge.dart';
import 'widgets/scan_card.dart';
import 'widgets/vulnerability_item.dart';

class ScanResultsScreen extends StatefulWidget {
  final int deviceId;

  const ScanResultsScreen({
    Key? key,
    required this.deviceId,
  }) : super(key: key);

  @override
  State<ScanResultsScreen> createState() => _ScanResultsScreenState();
}

class _ScanResultsScreenState extends State<ScanResultsScreen> {
  String _selectedFilter = 'all';
  bool _showOnlyCritical = false;
  bool _showTechnicalDetails = false;
  Device? _device;
  int? _expandedVulnerabilityIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    // Load device details
    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
    // If we haven't loaded devices yet or don't have the specific device
    if (deviceProvider.devices.isEmpty || !deviceProvider.devices.any((d) => d.id == widget.deviceId)) {
      try {
        await deviceProvider.loadDevices();
        // After loading, find the device
        setState(() {
          _device = deviceProvider.devices.firstWhere(
                (d) => d.id == widget.deviceId,
            orElse: () => Device(
              id: widget.deviceId,
              deviceName: 'Unknown Device',
              ipAddress: '',
              macAddress: '',
              createdAt: DateTime.now(),
            ),
          );
        });
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar('Failed to load device details: ${e.toString()}');
        }
      }
    } else {
      // Device is already loaded
      setState(() {
        _device = deviceProvider.devices.firstWhere(
              (d) => d.id == widget.deviceId,
          orElse: () => Device(
            id: widget.deviceId,
            deviceName: 'Unknown Device',
            ipAddress: '',
            macAddress: '',
            createdAt: DateTime.now(),
          ),
        );
      });
    }

    // Load scan history for this device
    final scanProvider = Provider.of<ScanProvider>(context, listen: false);
    try {
      await scanProvider.loadScans(deviceId: widget.deviceId);
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to load scan history: ${e.toString()}');
      }
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filter Scans', style: AppTextStyles.title),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Status', style: AppTextStyles.subtitle),
              const SizedBox(height: AppSpacing.small),
              DropdownButtonFormField<String>(
                value: _selectedFilter,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.small),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium),
                ),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Scans')),
                  DropdownMenuItem(value: 'completed', child: Text('Completed')),
                  DropdownMenuItem(value: 'inProgress', child: Text('In Progress')),
                  DropdownMenuItem(value: 'failed', child: Text('Failed')),
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedFilter = value);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.medium),
              Text('Issues', style: AppTextStyles.subtitle),
              const SizedBox(height: AppSpacing.small),
              CheckboxListTile(
                title: const Text('Show only critical issues'),
                value: _showOnlyCritical,
                onChanged: (value) {
                  setState(() => _showOnlyCritical = value ?? false);
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
              const SizedBox(height: AppSpacing.small),
              CheckboxListTile(
                title: const Text('Show technical details'),
                value: _showTechnicalDetails,
                onChanged: (value) {
                  setState(() => _showTechnicalDetails = value ?? false);
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
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
            label: 'Apply',
            onPressed: () {
              setState(() {});
              Navigator.pop(context);
            },
            buttonType: AppButtonType.primary,
          ),
        ],
      ),
    );
  }

  Future<void> _performScan(String scanType) async {
    final scanProvider = Provider.of<ScanProvider>(context, listen: false);

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
              Text('Initiating scan...'),
            ],
          ),
        ),
      );

      // Create the scan
      final scan = await scanProvider.createScan(
        deviceId: widget.deviceId,
        scanType: scanType,
      );

      // Close the loading dialog
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (scan == null) {
        _showErrorSnackBar(scanProvider.error ?? 'Failed to create scan');
        return;
      }

      _showSuccessSnackBar('Scan started successfully');

      // Refresh the scan list
      await scanProvider.loadScans(deviceId: widget.deviceId);

      // Scroll to the new scan (at the top)
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 300), () {
          Scrollable.ensureVisible(
            context,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        });
      }
    } catch (e) {
      // Close the loading dialog if still showing
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        _showErrorSnackBar('Error starting scan: $e');
      }
    }
  }

  Future<void> _exportScanResults(Scan scan) async {
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
              Text('Exporting scan results...'),
            ],
          ),
        ),
      );

      // Get provider
      final provider = context.read<ScanProvider>();

      // Export the scan
      await provider.exportScan(scan.scanId, format: 'pdf');

      // Close the loading dialog
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // Show success message
      _showSuccessSnackBar('Scan results exported successfully');
    } catch (e) {
      // Close the loading dialog if still showing
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        _showErrorSnackBar('Failed to export scan results: $e');
      }
    }
  }

  Future<void> _confirmDeleteScan(Scan scan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Scan', style: AppTextStyles.title),
        content: Text(
          'Are you sure you want to delete this scan? This action cannot be undone.',
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
        final provider = context.read<ScanProvider>();
        await provider.cancelScan(scan.scanId);

        // Reload scans after delete
        await provider.loadScans(deviceId: widget.deviceId);
        _showSuccessSnackBar('Scan deleted successfully');
      } catch (e) {
        _showErrorSnackBar('Failed to delete scan: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _device?.deviceName ?? 'Scan Results',
          style: AppTextStyles.title.copyWith(color: AppColors.onPrimary),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: Consumer<ScanProvider>(
          builder: (context, scanProvider, child) {
            if (scanProvider.isLoading) {
              return const Center(
                child: LoadingIndicator(),
              );
            }

            if (scanProvider.error != null) {
              return _buildErrorView(scanProvider);
            }

            final scans = _filterScans(scanProvider.scans);

            if (scans.isEmpty) {
              return _buildEmptyView();
            }

            return ListView(
              padding: const EdgeInsets.all(AppSpacing.medium),
              children: [
                // Device Info Card
                if (_device != null) _buildDeviceInfoCard(_device!),

                const SizedBox(height: AppSpacing.medium),

                // Scan History Section
                Text(
                  'Scan History',
                  style: AppTextStyles.title,
                ),
                const SizedBox(height: AppSpacing.small),

                // Scan List
                ...scans.map((scan) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.medium),
                  child: ScanCard(
                    scan: scan,
                    onTap: () => _navigateToScanDetails(scan),
                    onExport: () => _exportScanResults(scan),
                    onRescan: () => _performScan(scan.scanType),
                    onDelete: () => _confirmDeleteScan(scan),
                  ),
                )).toList(),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _startNewScan,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.security),
        tooltip: 'Start New Scan',
      ),
    );
  }

  Widget _buildDeviceInfoCard(Device device) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.small),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.small),
                  ),
                  child: Icon(
                    Icons.devices,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.small),
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
                      Text(
                        device.deviceType ?? 'Unknown Device Type',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                RiskLevelBadge(riskLevel: device.riskLevel),
              ],
            ),
            const SizedBox(height: AppSpacing.medium),
            const Divider(),
            const SizedBox(height: AppSpacing.small),
            _buildDetailRow(
              label: 'IP Address',
              value: device.ipAddress.isNotEmpty ? device.ipAddress : 'N/A',
              icon: Icons.language,
            ),
            _buildDetailRow(
              label: 'MAC Address',
              value: device.macAddress,
              icon: Icons.settings_ethernet,
            ),
            if (device.firmwareVersion != null && device.firmwareVersion!.isNotEmpty)
              _buildDetailRow(
                label: 'Firmware',
                value: device.firmwareVersion!,
                icon: Icons.system_update,
              ),
            _buildDetailRow(
              label: 'Last Scan',
              value: device.lastScanDate != null
                  ? DateFormatter.format(device.lastScanDate!)
                  : 'Never',
              icon: Icons.history,
            ),
            _buildDetailRow(
              label: 'Vulnerabilities',
              value: '${device.openVulnerabilities}',
              icon: Icons.warning,
              valueColor: device.openVulnerabilities > 0 ? AppColors.error : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    required IconData icon,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.small),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.small),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToScanDetails(Scan scan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.large)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return _buildScanDetailsSheet(context, scan, scrollController);
          },
        );
      },
    );
  }

  Widget _buildScanDetailsSheet(BuildContext context, Scan scan, ScrollController scrollController) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.large)),
      ),
      child: Column(
        children: [
          // Handle and header
          Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.small),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textDisabled,
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.medium,
              vertical: AppSpacing.small,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Scan Details',
                  style: AppTextStyles.title,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(),

          // Scan details content
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(AppSpacing.medium),
              children: [
                // Summary Card
                AppCard(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.medium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Scan Summary', style: AppTextStyles.subtitle),
                            const Spacer(),
                            RiskLevelBadge(riskLevel: scan.riskLevel),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.medium),

                        // Scan details
                        _buildDetailRow(
                          label: 'Scan ID',
                          value: '#${scan.scanId}',
                          icon: Icons.tag,
                        ),
                        _buildDetailRow(
                          label: 'Scan Type',
                          value: scan.scanType.toCapitalized(),
                          icon: Icons.category,
                        ),
                        _buildDetailRow(
                          label: 'Started',
                          value: scan.startedAt != null
                              ? DateFormatter.formatWithTime(scan.startedAt!)
                              : 'Not started',
                          icon: Icons.play_arrow,
                        ),
                        _buildDetailRow(
                          label: 'Completed',
                          value: scan.completedAt != null
                              ? DateFormatter.formatWithTime(scan.completedAt!)
                              : 'Not completed',
                          icon: Icons.stop,
                        ),
                        if (scan.scanDuration != null)
                          _buildDetailRow(
                            label: 'Duration',
                            value: '${scan.scanDuration!.toStringAsFixed(1)}s',
                            icon: Icons.timer,
                          ),
                        _buildDetailRow(
                          label: 'Status',
                          value: scan.status.toString().split('.').last.toCapitalized(),
                          icon: Icons.info,
                        ),
                        if (scan.securityScore != null)
                          _buildDetailRow(
                            label: 'Score',
                            value: '${scan.securityScore!.toStringAsFixed(1)}%',
                            icon: Icons.score,
                            valueColor: _getScoreColor(scan.securityScore!),
                          ),
                        _buildDetailRow(
                          label: 'Issues',
                          value: '${scan.vulnerabilitiesFound}',
                          icon: Icons.warning,
                          valueColor: scan.vulnerabilitiesFound > 0 ? AppColors.error : AppColors.success,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.medium),

                // Vulnerabilities Section
                if (scan.result.vulnerabilities.isNotEmpty) ...[
                  Text('Vulnerabilities', style: AppTextStyles.title),
                  const SizedBox(height: AppSpacing.small),
                  ...scan.result.vulnerabilities.asMap().entries.map((entry) {
                    final index = entry.key;
                    final vulnerability = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.small),
                      child: VulnerabilityItem(
                        vulnerability: vulnerability,
                        expanded: _expandedVulnerabilityIndex == index,
                        onExpansionChanged: (expanded) {
                          setState(() {
                            _expandedVulnerabilityIndex = expanded ? index : null;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ],

                const SizedBox(height: AppSpacing.medium),

                // Open Ports Section
                if (scan.result.openPorts.isNotEmpty) ...[
                  Text('Open Ports', style: AppTextStyles.title),
                  const SizedBox(height: AppSpacing.small),
                  AppCard(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.medium),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${scan.result.openPorts.length} Open ${scan.result.openPorts.length == 1 ? 'Port' : 'Ports'} Detected',
                            style: AppTextStyles.subtitle,
                          ),
                          const SizedBox(height: AppSpacing.small),
                          const Divider(),
                          ...scan.result.openPorts.map((port) => _buildPortItem(port)).toList(),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.medium),

                // Raw Data Section (Technical Details)
                if (_showTechnicalDetails && scan.result.rawData.isNotEmpty) ...[
                  Text('Technical Details', style: AppTextStyles.title),
                  const SizedBox(height: AppSpacing.small),
                  AppCard(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.medium),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...scan.result.rawData.entries.where((e) => e.value != null).map(
                                (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.small),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.key.replaceAll('_', ' ').toCapitalized(),
                                    style: AppTextStyles.subtitle,
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(AppSpacing.small),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(AppRadius.small),
                                    ),
                                    child: Text(
                                      _formatRawDataValue(entry.value),
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.small),
                                  const Divider(),
                                ],
                              ),
                            ),
                          ).toList(),
                        ],
                      ),
                    ),
                  ),
                ],

                // Action Buttons
                const SizedBox(height: AppSpacing.large),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Export Results',
                        icon: Icons.download,
                        onPressed: () {
                          Navigator.pop(context);
                          _exportScanResults(scan);
                        },
                        buttonType: AppButtonType.secondary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.medium),
                    Expanded(
                      child: AppButton(
                        label: 'Run Again',
                        icon: Icons.refresh,
                        onPressed: () {
                          Navigator.pop(context);
                          _performScan(scan.scanType);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortItem(PortInfo port) {
    final isSecure = port.service?.isSecure ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.small),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isSecure ? AppColors.success : AppColors.error).withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.small),
            ),
            child: Icon(
              Icons.router,
              size: 16,
              color: isSecure ? AppColors.success : AppColors.error,
            ),
          ),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Port ${port.portNumber} (${port.protocol.toUpperCase()})',
                  style: AppTextStyles.bodyBold,
                ),
                if (port.service != null)
                  Text(
                    '${port.service!.name}${port.service!.version != null ? ' v${port.service!.version}' : ''}',
                    style: AppTextStyles.bodySmall,
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (isSecure ? AppColors.success : AppColors.error).withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            child: Text(
              isSecure ? 'SECURE' : 'INSECURE',
              style: TextStyle(
                color: isSecure ? AppColors.success : AppColors.error,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 90) return AppColors.success;
    if (score >= 70) return AppColors.info;
    if (score >= 50) return AppColors.warning;
    return AppColors.error;
  }

  String _formatRawDataValue(dynamic value) {
    if (value is Map || value is List) {
      return const JsonEncoder.withIndent('  ').convert(value);
    }
    return value.toString();
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
                Icons.search_off,
                size: 64,
                color: AppColors.textDisabled,
              ),
              const SizedBox(height: AppSpacing.medium),
              Text(
                'No scan results found',
                style: AppTextStyles.title,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.small),
              Text(
                'Start a new scan to analyze this device',
                style: TextStyle(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.large),
              AppButton(
                label: 'Start New Scan',
                icon: Icons.security,
                onPressed: _startNewScan,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView(ScanProvider provider) {
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
                'Error loading scan results',
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
                onPressed: _loadData,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension StringCasingExtension on String {
  String toCapitalized() => length > 0
      ? '${this[0].toUpperCase()}${substring(1)}'
      : '';

  String toTitleCase() => replaceAll(RegExp(' +'), ' ')
      .split(' ')
      .map((str) => str.toCapitalized())
      .join(' ');
}

// This is the fix for the broken methods at the end of scan_results_screen.dart

List<Scan> _filterScans(List<Scan> scans) {
  return scans.where((scan) {
    if (_selectedFilter != 'all' &&
        scan.status.toString().split('.').last != _selectedFilter) {
      return false;
    }
    if (_showOnlyCritical && scan.riskLevel != RiskLevel.critical) {
      return false;
    }
    return true;
  }).toList();
}

Future<void> _startNewScan() async {
  if (_device == null) {
    _showErrorSnackBar('Device details not available');
    return;
  }

  String selectedScanType = 'full';

  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Start New Scan', style: AppTextStyles.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select scan type:', style: AppTextStyles.body),
          const SizedBox(height: AppSpacing.medium),
          StatefulBuilder(
            builder: (context, setState) => DropdownButtonFormField<String>(
              value: selectedScanType,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.small),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium),
              ),
              items: const [
                DropdownMenuItem(value: 'quick', child: Text('Quick Scan')),
                DropdownMenuItem(value: 'full', child: Text('Full Scan')),
                DropdownMenuItem(value: 'custom', child: Text('Custom Scan')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedScanType = value;
                  });
                }
              },
            ),
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
            selectedScanType == 'quick'
                ? 'Basic scan of essential security checks (1-2 min)'
                : selectedScanType == 'full'
                ? 'Comprehensive security assessment (3-5 min)'
                : 'Customize scan parameters (Advanced)',
            style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        AppButton(
          label: 'Start Scan',
          onPressed: () {
            Navigator.pop(context);
            _performScan(selectedScanType);
          },
          buttonType: AppButtonType.primary,
        ),
      ],
    ),
  );
}