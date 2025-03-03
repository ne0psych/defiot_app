// lib/screens/scans/scan_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../models/device_model.dart';
import '../../providers/device_provider.dart';
import '../../providers/scan_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/search_field.dart';
import '../../widgets/security/risk_level_badge.dart';
import '../../widgets/security/status_badge.dart';
import 'scan_results_screen.dart';
import 'widgets/scan_card.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({Key? key}) : super(key: key);

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  List<Device> selectedDevices = [];
  ScanProvider? _scanProvider;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();

    // Load devices when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDevices();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scanProvider ??= Provider.of<ScanProvider>(context, listen: false);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadDevices() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
      await deviceProvider.loadDevices();
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to load devices: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _startScan(BuildContext context) async {
    if (!mounted) return;

    try {
      _scanProvider ??= Provider.of<ScanProvider>(context, listen: false);
      final devices = selectedDevices;

      if (devices.isEmpty) {
        _showErrorSnackBar('Please select at least one device to scan');
        return;
      }

      // Check all devices for valid IP addresses
      for (var device in devices) {
        if (device.ipAddress.isEmpty) {
          _showErrorSnackBar('Device ${device.deviceName} has no IP address');
          return;
        }
      }

      // Show progress dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
              title: const Text('Scanning Devices'),
              content: Consumer<ScanProvider>(
                builder: (context, provider, _) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const LoadingIndicator(),
                      const SizedBox(height: AppSpacing.medium),
                      Text(
                        'Scanning ${selectedDevices.length} device${selectedDevices.length > 1 ? 's' : ''}',
                        style: AppTextStyles.body,
                      ),
                      const SizedBox(height: AppSpacing.small),
                      if (provider.batchProgress > 0)
                        LinearProgressIndicator(
                          value: provider.batchProgress,
                          backgroundColor: AppColors.background,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      const SizedBox(height: AppSpacing.small),
                      if (provider.error != null)
                        Text(
                          'Error: ${provider.error}',
                          style: TextStyle(color: AppColors.error),
                        ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      );

      final completedScans = await _scanProvider!.createBatchScans(devices, 'full');

      // Close progress dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (completedScans.isEmpty) {
        _showErrorSnackBar(_scanProvider!.error ?? 'No scans were completed');
        return;
      }

      // Show success snackbar
      _showSuccessSnackBar('Scan completed successfully');

      // Navigate to scan results for the first device
      if (mounted && completedScans.isNotEmpty) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ScanResultsScreen(deviceId: completedScans.first.deviceId),
          ),
        );
      }
    } catch (e) {
      // Handle unexpected errors
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        _showErrorSnackBar('Unexpected error: $e');
      }
    }
  }

  void _selectAllDevices(List<Device> devices, bool selected) {
    setState(() {
      if (selected) {
        // Select all devices
        selectedDevices = List.from(devices);
        for (var device in devices) {
          device.isSelected = true;
        }
      } else {
        // Deselect all devices
        selectedDevices.clear();
        for (var device in devices) {
          device.isSelected = false;
        }
      }
    });
  }

  void _toggleDevice(Device device, bool? isSelected) {
    setState(() {
      device.isSelected = isSelected ?? false;

      if (device.isSelected && !selectedDevices.contains(device)) {
        selectedDevices.add(device);
      } else if (!device.isSelected) {
        selectedDevices.remove(device);
      }
    });
  }

  List<Device> _filterDevices(List<Device> devices) {
    if (_searchQuery.isEmpty) return devices;

    return devices.where((device) =>
    device.deviceName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (device.deviceType?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
        (device.ipAddress.toLowerCase().contains(_searchQuery.toLowerCase()))
    ).toList();
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
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: AppColors.onError,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
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
        action: selectedDevices.isNotEmpty
            ? SnackBarAction(
          label: 'VIEW RESULTS',
          textColor: AppColors.onSuccess,
          onPressed: () {
            if (!mounted) return;
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ScanResultsScreen(
                  deviceId: selectedDevices.first.deviceId,
                ),
              ),
            );
          },
        )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          // Enhanced Header
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + AppSpacing.medium,
              bottom: AppSpacing.medium,
              left: AppSpacing.medium,
              right: AppSpacing.medium,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(AppRadius.large),
                bottomRight: Radius.circular(AppRadius.large),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Device Scanner',
                  style: AppTextStyles.headline.copyWith(color: AppColors.onPrimary),
                ),
                const SizedBox(height: AppSpacing.medium),
                // Search Field
                SearchField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  hintText: 'Search devices by name or IP',
                ),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: _isLoading
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const LoadingIndicator(),
                  const SizedBox(height: AppSpacing.medium),
                  Text(
                    'Loading devices...',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
                : Consumer<DeviceProvider>(
              builder: (context, deviceProvider, child) {
                if (deviceProvider.error != null) {
                  return _buildErrorView(deviceProvider);
                }

                final devices = _filterDevices(deviceProvider.devices);
                final bool allSelected = devices.isNotEmpty &&
                    devices.every((device) => device.isSelected);

                return RefreshIndicator(
                  onRefresh: _loadDevices,
                  color: AppColors.primary,
                  child: devices.isEmpty
                      ? _buildEmptyView()
                      : SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.medium),
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Devices Section Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Available Devices',
                              style: AppTextStyles.title,
                            ),
                            TextButton.icon(
                              icon: Icon(
                                allSelected ? Icons.deselect : Icons.select_all,
                                size: 18,
                              ),
                              label: Text(
                                allSelected ? 'Deselect All' : 'Select All',
                                style: AppTextStyles.button,
                              ),
                              onPressed: () => _selectAllDevices(devices, !allSelected),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.small),

                        // Devices List
                        _buildDevicesList(devices),
                        const SizedBox(height: AppSpacing.large),

                        // Scan Button
                        AppButton(
                          label: 'START SCAN',
                          icon: Icons.security,
                          onPressed: selectedDevices.isNotEmpty
                              ? () => _startScan(context)
                              : null,
                          isLoading: _scanProvider?.isLoading ?? false,
                          suffixWidget: selectedDevices.isNotEmpty
                              ? Container(
                            margin: const EdgeInsets.only(left: AppSpacing.small),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.small,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.onPrimary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(AppRadius.medium),
                            ),
                            child: Text(
                              '${selectedDevices.length} selected',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.onPrimary,
                              ),
                            ),
                          )
                              : null,
                          expanded: true,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.large),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.devices_other,
                  size: 64,
                  color: AppColors.textDisabled,
                ),
                const SizedBox(height: AppSpacing.medium),
                Text(
                  'No devices found',
                  style: AppTextStyles.title,
                ),
                const SizedBox(height: AppSpacing.small),
                Text(
                  'Add devices to start scanning',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.large),
                AppButton(
                  label: 'Add Device',
                  icon: Icons.add,
                  onPressed: () {
                    // Navigate to add device screen
                    Navigator.of(context).pushNamed(AppConstants.routeAddDevice);
                  },
                ),
                const SizedBox(height: AppSpacing.medium),
                AppButton(
                  label: 'Refresh Devices',
                  icon: Icons.refresh,
                  onPressed: _loadDevices,
                  buttonType: AppButtonType.secondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView(DeviceProvider provider) {
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
                'Error loading devices',
                style: AppTextStyles.title,
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
                onPressed: _loadDevices,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDevicesList(List<Device> devices) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: devices.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: AppColors.divider,
        ),
        itemBuilder: (context, index) {
          final device = devices[index];
          final bool isOnline = device.status == DeviceStatus.active;

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.medium,
              vertical: AppSpacing.small,
            ),
            leading: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.small),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                  ),
                  child: Icon(
                    Icons.devices,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                StatusBadge(
                  isActive: isOnline,
                  size: 14,
                ),
              ],
            ),
            title: Text(
              device.deviceName,
              style: AppTextStyles.subtitle,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        color: isOnline ? AppColors.success : AppColors.error,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '•',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      device.deviceType ?? 'Unknown',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                if (device.ipAddress.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    device.ipAddress,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
                if (device.openVulnerabilities > 0) ...[
                  const SizedBox(height: 8),
                  RiskLevelBadge(riskLevel: device.riskLevel),
                ],
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.history),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ScanResultsScreen(deviceId: device.id),
                      ),
                    );
                  },
                  tooltip: 'View Scan History',
                  iconSize: 20,
                  color: AppColors.primary,
                ),
                Checkbox(
                  value: device.isSelected,
                  onChanged: (value) => _toggleDevice(device, value),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  activeColor: AppColors.primary,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}