// lib/screens/devices/add_device_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/device_model.dart';
import '../../providers/device_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/app_button.dart';
import 'widgets/device_form.dart';

class AddDeviceScreen extends StatefulWidget {
  final Device? device;

  const AddDeviceScreen({
    Key? key,
    this.device,
  }) : super(key: key);

  @override
  State<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  bool _isLoading = false;
  String? _error;

  Future<void> _handleFormSubmit(Map<String, dynamic> formData) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);

      if (widget.device != null) {
        // Update existing device
        final success = await deviceProvider.updateDevice(
          widget.device!.id,
          deviceName: formData['device_name'],
          deviceType: formData['device_type'],
          ipAddress: formData['ip_address'],
          firmwareVersion: formData['firmware_version'],
          status: _parseStatus(formData['status']),
          securityDetails: formData['security_details'],
        );

        if (success) {
          if (mounted) {
            _showSnackBar('Device updated successfully');
            Navigator.pop(context);
          }
        } else {
          throw Exception(deviceProvider.error ?? 'Failed to update device');
        }
      } else {
        // Create new device
        final device = await deviceProvider.addDevice(
          deviceName: formData['device_name'],
          deviceType: formData['device_type'],
          macAddress: formData['mac_address'],
          ipAddress: formData['ip_address'],
          firmwareVersion: formData['firmware_version'],
        );

        if (device != null) {
          if (mounted) {
            _showSnackBar('Device added successfully');
            Navigator.pop(context);
          }
        } else {
          throw Exception(deviceProvider.error ?? 'Failed to add device');
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      _showSnackBar('Error: $_error', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  DeviceStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return DeviceStatus.active;
      case 'inactive':
        return DeviceStatus.inactive;
      default:
        return DeviceStatus.unknown;
    }
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
    final isEditMode = widget.device != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Device' : 'Add Device'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Intro Text
            Text(
              isEditMode
                  ? 'Edit device details'
                  : 'Add a new device to monitor',
              style: AppTextStyles.subtitle,
            ),
            Text(
              isEditMode
                  ? 'Update information for ${widget.device!.deviceName}'
                  : 'Fill in the details below to add a new IoT device',
              style: AppTextStyles.bodySmall,
            ),

            // Error Display
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.medium),
              Container(
                padding: const EdgeInsets.all(AppSpacing.medium),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                  border: Border.all(
                    color: AppColors.error,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: AppColors.error),
                    const SizedBox(width: AppSpacing.small),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _error = null),
                      color: AppColors.error,
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.large),

            // Device Form
            DeviceForm(
              device: widget.device,
              onSubmit: _handleFormSubmit,
              onCancel: () => Navigator.pop(context),
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}