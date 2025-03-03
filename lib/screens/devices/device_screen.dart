// lib/screens/devices/device_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/config/app_routes.dart';
import '../../models/device_model.dart';
import '../../providers/device_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/search_field.dart';
import 'widgets/device_card.dart';
import 'add_device_screen.dart';
import 'device_details_screen.dart';

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({Key? key}) : super(key: key);

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final FocusNode _searchFocusNode = FocusNode();
  bool _isLoading = false;
  String? _deviceTypeFilter;
  RiskLevel? _riskLevelFilter;
  DeviceStatus? _statusFilter;
  bool _multiSelectMode = false;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadDevices() async {
    setState(() => _isLoading = true);

    try {
      final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
      await deviceProvider.loadDevices(
        deviceType: _deviceTypeFilter,
        minRiskLevel: _riskLevelFilter,
        status: _statusFilter,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Device> _filterDevices(List<Device> devices) {
    if (_searchQuery.isEmpty) return devices;

    return devices.where((device) =>
    device.deviceName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (device.ipAddress.isNotEmpty && device.ipAddress.toLowerCase().contains(_searchQuery.toLowerCase())) ||
        (device.deviceType != null && device.deviceType!.toLowerCase().contains(_searchQuery.toLowerCase()))
    ).toList();
  }

  void _addDevice() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddDeviceScreen(),
      ),
    ).then((_) => _loadDevices());
  }

  void _viewDeviceDetails(Device device) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeviceDetailsScreen(deviceId: device.id),
      ),
    ).then((_) => _loadDevices());
  }

  void _deleteDevice(Device device) async {
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Device'),
        content: Text(
          'Are you sure you want to delete ${device.deviceName}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'DELETE',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);

      try {
        final success = await deviceProvider.deleteDevice(device.id);
        if (success) {
          _showSnackBar('Device deleted successfully');
        } else {
          _showSnackBar('Failed to delete device: ${deviceProvider.error}', isError: true);
        }
      } catch (e) {
        _showSnackBar('Error: $e', isError: true);
      }
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Filter Devices'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Device Type Filter
                  Text('Device Type', style: AppTextStyles.subtitle),
                  const SizedBox(height: AppSpacing.small),
                  DropdownButtonFormField<String?>(
                    value: _deviceTypeFilter,
                    decoration: AppWidgetStyles.textFieldDecoration(
                      hintText: 'Select device type',
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All Types'),
                      ),
                      ...['smart_camera', 'smart_lock', 'thermostat', 'router', 'other'].map((type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type.replaceAll('_', ' ').toCapitalized()),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _deviceTypeFilter = value;
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.medium),

                  // Risk Level Filter
                  Text('Risk Level', style: AppTextStyles.subtitle),
                  const SizedBox(height: AppSpacing.small),
                  DropdownButtonFormField<RiskLevel?>(
                    value: _riskLevelFilter,
                    decoration: AppWidgetStyles.textFieldDecoration(
                      hintText: 'Select risk level',
                    ),
                    items: [
                      const DropdownMenuItem<RiskLevel?>(
                        value: null,
                        child: Text('All Risk Levels'),
                      ),
                      ...RiskLevel.values.map((level) {
                        return DropdownMenuItem<RiskLevel>(
                          value: level,
                          child: Text(level.toString().split('.').last.toCapitalized()),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _riskLevelFilter = value;
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.medium),

                  // Status Filter
                  Text('Status', style: AppTextStyles.subtitle),
                  const SizedBox(height: AppSpacing.small),
                  DropdownButtonFormField<DeviceStatus?>(
                    value: _statusFilter,
                    decoration: AppWidgetStyles.textFieldDecoration(
                      hintText: 'Select status',
                    ),
                    items: [
                      const DropdownMenuItem<DeviceStatus?>(
                        value: null,
                        child: Text('All Statuses'),
                      ),
                      ...DeviceStatus.values.map((status) {
                        return DropdownMenuItem<DeviceStatus>(
                          value: status,
                          child: Text(status.toString().split('.').last.toCapitalized()),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _statusFilter = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _deviceTypeFilter = null;
                    _riskLevelFilter = null;
                    _statusFilter = null;
                  });
                },
                child: const Text('RESET'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('CANCEL'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _loadDevices();
                },
                child: const Text('APPLY'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
        margin: const EdgeInsets.all(AppSpacing.small),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // App Bar with search
          _buildAppBar(),

          // Main content
          Expanded(
            child: Consumer<DeviceProvider>(
              builder: (context, deviceProvider, child) {
                if (deviceProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (deviceProvider.error != null) {
                  return ErrorView(
                    error: deviceProvider.error!,
                    onRetry: _loadDevices,
                  );
                }

                final filteredDevices = _filterDevices(deviceProvider.devices);

                if (filteredDevices.isEmpty) {
                  return _buildEmptyState(deviceProvider.devices.isEmpty);
                }

                return RefreshIndicator(
                  onRefresh: _loadDevices,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.medium),
                    itemCount: filteredDevices.length,
                    itemBuilder: (context, index) {
                      final device = filteredDevices[index];
                      return DeviceCard(
                        device: device,
                        onTap: _multiSelectMode
                            ? null
                            : () => _viewDeviceDetails(device),
                        onEdit: _multiSelectMode
                            ? null
                            : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddDeviceScreen(device: device),
                          ),
                        ).then((_) => _loadDevices()),
                        onDelete: _multiSelectMode
                            ? null
                            : () => _deleteDevice(device),
                        selectable: _multiSelectMode,
                        isSelected: device.isSelected,
                        onSelectChanged: _multiSelectMode
                            ? (selected) {
                          deviceProvider.selectDevice(device, selected);
                        }
                            : null,
                      );
                    },
                  ),
                );
              },
            ),
          ),

          // Bottom action bar for multi-select mode
          if (_multiSelectMode) _buildMultiSelectBar(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addDevice,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        bottom: AppSpacing.medium,
        left: AppSpacing.medium,
        right: AppSpacing.medium,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'My Devices',
                  style: AppTextStyles.heading2.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  _multiSelectMode ? Icons.close : Icons.checklist,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _multiSelectMode = !_multiSelectMode;
                  });

                  // Clear selections when exiting multi-select mode
                  if (!_multiSelectMode) {
                    Provider.of<DeviceProvider>(context, listen: false)
                        .selectAllDevices(false);
                  }
                },
                tooltip: _multiSelectMode ? 'Cancel Selection' : 'Select Multiple',
              ),
              IconButton(
                icon: const Icon(Icons.filter_list, color: Colors.white),
                onPressed: _showFilterDialog,
                tooltip: 'Filter Devices',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          SearchField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            hintText: 'Search devices by name, IP or type',
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool noDevices) {
    return EmptyState(
      icon: Icons.devices,
      title: noDevices ? 'No Devices Found' : 'No Matching Devices',
      message: noDevices
          ? 'Add your first device to start monitoring it'
          : 'Try adjusting your filters or search term',
      buttonText: noDevices ? 'Add Device' : 'Clear Filters',
      onButtonPressed: noDevices ? _addDevice : () {
        setState(() {
          _searchController.clear();
          _searchQuery = '';
          _deviceTypeFilter = null;
          _riskLevelFilter = null;
          _statusFilter = null;
        });
        _loadDevices();
      },
    );
  }

  Widget _buildMultiSelectBar() {
    final deviceProvider = Provider.of<DeviceProvider>(context);
    final selectedCount = deviceProvider.devices.where((d) => d.isSelected).length;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Checkbox(
            value: selectedCount > 0 && selectedCount == deviceProvider.devices.length,
            tristate: selectedCount > 0 && selectedCount < deviceProvider.devices.length,
            onChanged: (value) {
              deviceProvider.selectAllDevices(value ?? false);
            },
            activeColor: AppColors.primary,
          ),
          Text(
            selectedCount > 0
                ? '$selectedCount selected'
                : 'Select devices',
            style: AppTextStyles.subtitle,
          ),
          const Spacer(),
          if (selectedCount > 0) ...[
            AppButton(
              text: 'Scan Selected',
              icon: Icons.security,
              onPressed: () {
                // Navigate to scan screen with selected devices
                Navigator.pushNamed(context, AppRoutes.scan);
              },
              type: AppButtonType.primary,
            ),
          ],
        ],
      ),
    );
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