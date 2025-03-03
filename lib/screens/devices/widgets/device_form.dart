// lib/screens/devices/widgets/device_form.dart
import 'package:flutter/material.dart';
import '../../../models/device_model.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common/app_button.dart';

class DeviceForm extends StatefulWidget {
  final Device? device;
  final Function(Map<String, dynamic> formData) onSubmit;
  final VoidCallback? onCancel;
  final bool isLoading;

  const DeviceForm({
    Key? key,
    this.device,
    required this.onSubmit,
    this.onCancel,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<DeviceForm> createState() => _DeviceFormState();
}

class _DeviceFormState extends State<DeviceForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _deviceNameController;
  late final TextEditingController _deviceTypeController;
  late final TextEditingController _macAddressController;
  late final TextEditingController _ipAddressController;
  late final TextEditingController _firmwareVersionController;

  late DeviceStatus _selectedStatus;

  final List<String> _deviceTypes = [
    'smart_camera',
    'smart_lock',
    'thermostat',
    'smart_speaker',
    'smart_light',
    'smart_outlet',
    'router',
    'gateway',
    'other'
  ];

  String? _selectedDeviceType;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with existing device data if in edit mode
    final device = widget.device;
    _deviceNameController = TextEditingController(text: device?.deviceName);
    _deviceTypeController = TextEditingController(text: device?.deviceType);
    _macAddressController = TextEditingController(text: device?.macAddress);
    _ipAddressController = TextEditingController(text: device?.ipAddress);
    _firmwareVersionController = TextEditingController(
      text: device?.firmwareVersion ?? device?.securityDetails['firmware_version'],
    );

    _selectedStatus = device?.status ?? DeviceStatus.active;
    _selectedDeviceType = device?.deviceType;
  }

  @override
  void dispose() {
    _deviceNameController.dispose();
    _deviceTypeController.dispose();
    _macAddressController.dispose();
    _ipAddressController.dispose();
    _firmwareVersionController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final formData = {
        'device_name': _deviceNameController.text.trim(),
        'device_type': _selectedDeviceType ?? _deviceTypeController.text.trim(),
        'mac_address': _macAddressController.text.trim(),
        'ip_address': _ipAddressController.text.trim(),
        'firmware_version': _firmwareVersionController.text.trim(),
        'status': _selectedStatus.toString().split('.').last,
      };

      // Add security details for firmware
      if (_firmwareVersionController.text.trim().isNotEmpty) {
        formData['security_details'] = {
          'firmware_version': _firmwareVersionController.text.trim(),
        };
      }

      widget.onSubmit(formData);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.device != null;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Device Name
          TextFormField(
            controller: _deviceNameController,
            decoration: AppWidgetStyles.textFieldDecoration(
              labelText: 'Device Name',
              hintText: 'Enter device name',
              prefixIcon: Icons.devices,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter device name';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.medium),

          // Device Type
          DropdownButtonFormField<String>(
            value: _selectedDeviceType,
            decoration: AppWidgetStyles.textFieldDecoration(
              labelText: 'Device Type',
              hintText: 'Select device type',
              prefixIcon: Icons.category,
            ),
            items: _deviceTypes.map((type) {
              return DropdownMenuItem<String>(
                value: type,
                child: Text(
                  type.replaceAll('_', ' ').toCapitalized(),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedDeviceType = value;
              });
            },
            validator: (value) {
              // Device type is optional
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.medium),

          // MAC Address
          TextFormField(
            controller: _macAddressController,
            decoration: AppWidgetStyles.textFieldDecoration(
              labelText: 'MAC Address',
              hintText: 'XX:XX:XX:XX:XX:XX',
              prefixIcon: Icons.wifi,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter MAC address';
              }

              final macRegExp = RegExp(r'^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$');
              if (!macRegExp.hasMatch(value)) {
                return 'Invalid MAC address format';
              }

              return null;
            },
          ),
          const SizedBox(height: AppSpacing.medium),

          // IP Address
          TextFormField(
            controller: _ipAddressController,
            decoration: AppWidgetStyles.textFieldDecoration(
              labelText: 'IP Address',
              hintText: '192.168.1.1',
              prefixIcon: Icons.language,
            ),
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                final ipRegExp = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
                if (!ipRegExp.hasMatch(value)) {
                  return 'Invalid IP address format';
                }
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.medium),

          // Firmware Version
          TextFormField(
            controller: _firmwareVersionController,
            decoration: AppWidgetStyles.textFieldDecoration(
              labelText: 'Firmware Version',
              hintText: 'e.g., 1.2.3',
              prefixIcon: Icons.system_update,
            ),
          ),
          const SizedBox(height: AppSpacing.medium),

          // Device Status (only for edit mode)
          if (isEditMode) ...[
            Text(
              'Device Status',
              style: AppTextStyles.subtitle,
            ),
            const SizedBox(height: AppSpacing.small),

            Row(
              children: [
                Radio<DeviceStatus>(
                  value: DeviceStatus.active,
                  groupValue: _selectedStatus,
                  onChanged: (DeviceStatus? value) {
                    setState(() {
                      _selectedStatus = value ?? DeviceStatus.active;
                    });
                  },
                  activeColor: AppColors.primary,
                ),
                const Text('Active'),
                const SizedBox(width: AppSpacing.medium),

                Radio<DeviceStatus>(
                  value: DeviceStatus.inactive,
                  groupValue: _selectedStatus,
                  onChanged: (DeviceStatus? value) {
                    setState(() {
                      _selectedStatus = value ?? DeviceStatus.inactive;
                    });
                  },
                  activeColor: AppColors.primary,
                ),
                const Text('Inactive'),
              ],
            ),
            const SizedBox(height: AppSpacing.medium),
          ],

          // Form Actions
          Row(
            children: [
              if (widget.onCancel != null) ...[
                Expanded(
                  child: AppButton(
                    text: 'Cancel',
                    onPressed: widget.onCancel,
                    type: AppButtonType.outlined,
                    fullWidth: true,
                  ),
                ),
                const SizedBox(width: AppSpacing.medium),
              ],
              Expanded(
                child: AppButton(
                  text: isEditMode ? 'Update Device' : 'Add Device',
                  onPressed: _submitForm,
                  isLoading: widget.isLoading,
                  type: AppButtonType.primary,
                  fullWidth: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Extension to capitalize string
extension StringExtension on String {
  String toCapitalized() => this.isEmpty
      ? ''
      : '${this[0].toUpperCase()}${this.substring(1)}';

  String toTitleCase() => this.replaceAll(RegExp(' +'), ' ')
      .split(' ')
      .map((str) => str.toCapitalized())
      .join(' ');
}