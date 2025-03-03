// lib/screens/devices/device_details_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/device_model.dart';
import '../../models/scan_model.dart';
import '../../models/vulnerability_model.dart';
import '../../providers/device_provider.dart';
import '../../providers/scan_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/security/risk_level_badge.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/security/status_badge.dart';
import '../scan_results_screen.dart';
import 'add_device_screen.dart';

class DeviceDetailsScreen extends StatefulWidget {
  final int deviceId;

  const DeviceDetailsScreen({
    Key? key,
    required this.deviceId,
  }) : super(key: key);

  @override
  State<DeviceDetailsScreen> createState() => _DeviceDetailsScreenState();
}

class _DeviceDetailsScreenState extends State<DeviceDetailsScreen> {
  bool _isLoading = true;
  Device? _device;
  List<Scan>? _deviceScans;
  List<Vulnerability>? _vulnerabilities;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDeviceData();
  }

  Future<void> _loadDeviceData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load device details
      final deviceProvider = Provider.of<DeviceProvider>(
          context, listen: false);

      // First try to find the device in the provider's list
      _device = deviceProvider.devices.firstWhere(
            (d) => d.id == widget.deviceId,
        orElse: () => throw Exception('Device not found'),
      );

      // Load device vulnerabilities
      await deviceProvider.loadDeviceVulnerabilities(widget.deviceId);
      _vulnerabilities =
          deviceProvider.getDeviceVulnerabilities(widget.deviceId);

      // Load device scan history
      final scanProvider = Provider.of<ScanProvider>(context, listen: false);
      await scanProvider.loadScans(deviceId: widget.deviceId, limit: 10);
      _deviceScans = scanProvider.getDeviceScans(widget.deviceId);
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Delete Device'),
            content: Text(
              'Are you sure you want to delete ${_device
                  ?.deviceName}? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _deleteDevice();
                },
                child: Text(
                  'DELETE',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteDevice() async {
    setState(() => _isLoading = true);

    try {
      final deviceProvider = Provider.of<DeviceProvider>(
          context, listen: false);
      final success = await deviceProvider.deleteDevice(widget.deviceId);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Device ${_device?.deviceName} deleted successfully'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pop();
        }
      } else {
        throw Exception(deviceProvider.error ?? 'Failed to delete device');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
      _showSnackBar('Error: $_error', isError: true);
    }
  }

  // Implementation of the _scanDevice method for DeviceDetailsScreen

  Future<void> _scanDevice() async {
    if (_device == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final scanProvider = Provider.of<ScanProvider>(context, listen: false);

      // Show a dialog to let the user choose the scan type
      final scanType = await _showScanTypeDialog();
      if (scanType == null) {
        setState(() => _isLoading = false);
        return; // User cancelled
      }

      // Start the scan with the selected type
      final scan = await scanProvider.createScan(
        deviceId: widget.deviceId,
        scanType: scanType,
        customOptions: {
          'timeout': 120,
          'device_type': _device!.deviceType,
        },
      );

      if (scan != null) {
        if (mounted) {
          _showSnackBar('Scan started successfully');

          // Start polling for scan completion
          _pollScanStatus(scan.scanId);
        }
      } else {
        throw Exception(scanProvider.error ?? 'Failed to start scan');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
      _showSnackBar('Error: $_error', isError: true);
    }
  }

// Dialog to choose scan type
  Future<String?> _showScanTypeDialog() async {
    return showDialog<String>(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Scan Type'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select the type of security scan to perform:',
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: AppSpacing.medium),

                // Quick Scan Option
                _buildScanTypeOption(
                  title: 'Quick Scan',
                  description: 'Fast scan for common vulnerabilities',
                  icon: Icons.speed,
                  value: 'quick',
                ),
                const SizedBox(height: AppSpacing.small),

                // Full Scan Option
                _buildScanTypeOption(
                  title: 'Full Scan',
                  description: 'Comprehensive security assessment',
                  icon: Icons.security,
                  value: 'full',
                ),
                const SizedBox(height: AppSpacing.small),

                // Custom Scan Option
                _buildScanTypeOption(
                  title: 'Custom Scan',
                  description: 'Targeted scan for specific issues',
                  icon: Icons.tune,
                  value: 'custom',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('CANCEL'),
              ),
            ],
          ),
    );
  }

// Helper to build scan type option
  Widget _buildScanTypeOption({
    required String title,
    required String description,
    required IconData icon,
    required String value,
  }) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(value),
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.small),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: AppSpacing.small),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.subtitle),
                  Text(
                    description,
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

// Poll for scan completion
  Future<void> _pollScanStatus(int scanId) async {
    bool isScanComplete = false;
    int retryCount = 0;
    const maxRetries = 30; // 5 minutes with 10-second intervals

    while (!isScanComplete && retryCount < maxRetries) {
      try {
        // Wait before checking
        await Future.delayed(const Duration(seconds: 10));

        // Check scan status
        final scanProvider = Provider.of<ScanProvider>(context, listen: false);
        final scan = await scanProvider.getScan(scanId);

        if (scan == null) {
          // Scan not found, exit polling
          break;
        }

        if (scan.status == ScanStatus.completed ||
            scan.status == ScanStatus.failed) {
          isScanComplete = true;

          // Update UI with new data
          await _loadDeviceData();

          if (mounted) {
            if (scan.status == ScanStatus.completed) {
              _showSnackBar('Scan completed successfully', isError: false);
            } else {
              _showSnackBar(
                  'Scan failed: ${scan.result?.status ?? "Unknown error"}',
                  isError: true);
            }
          }
        }

        retryCount++;
      } catch (e) {
        // Error during polling, continue to next try
        retryCount++;
      }
    }

    // Ensure loading is false when polling ends
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}