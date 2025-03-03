// lib/screens/settings/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/loading_indicator.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = false;

  // Local state to track changes
  late bool _pushNotifications;
  late bool _emailNotifications;
  late bool _newDeviceAlerts;
  late bool _securityAlerts;
  late bool _marketingEmails;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _initializeSettings();
  }

  void _initializeSettings() {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _pushNotifications = settingsProvider.pushNotifications;
    _emailNotifications = settingsProvider.emailNotifications;
    _newDeviceAlerts = settingsProvider.newDeviceAlerts;
    _securityAlerts = settingsProvider.securityAlerts;
    _marketingEmails = settingsProvider.marketingEmails;
  }

  Future<void> _saveSettings() async {
    if (!_hasChanges) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

      await settingsProvider.updateNotificationSettings(
        pushNotifications: _pushNotifications,
        emailNotifications: _emailNotifications,
        newDeviceAlerts: _newDeviceAlerts,
        securityAlerts: _securityAlerts,
        marketingEmails: _marketingEmails,
      );

      if (mounted) {
        if (settingsProvider.error != null) {
          _showErrorSnackBar(settingsProvider.error!);
        } else {
          _showSuccessSnackBar('Notification settings updated successfully');
          setState(() {
            _hasChanges = false;
          });
        }
      }
    } catch (e) {
      _showErrorSnackBar('Failed to update settings: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
        title: const Text('Notifications'),
        actions: [
          _isLoading
              ? const Padding(
            padding: EdgeInsets.all(16.0),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
          )
              : IconButton(
            icon: const Icon(Icons.save),
            onPressed: _hasChanges ? _saveSettings : null,
            tooltip: 'Save Changes',
          ),
        ],
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, _) {
          return _isLoading
              ? const Center(child: LoadingIndicator())
              : ListView(
            children: [
              // Notification Types Section
              _buildSectionHeader('NOTIFICATION PREFERENCES'),

              // Push Notifications
              _buildSwitchTile(
                title: 'Push Notifications',
                subtitle: 'Receive important alerts on your device',
                icon: Icons.notifications,
                value: _pushNotifications,
                onChanged: (value) {
                  setState(() {
                    _pushNotifications = value;
                    _hasChanges = true;
                  });
                },
              ),

              // Email Notifications
              _buildSwitchTile(
                title: 'Email Notifications',
                subtitle: 'Receive important alerts via email',
                icon: Icons.email,
                value: _emailNotifications,
                onChanged: (value) {
                  setState(() {
                    _emailNotifications = value;
                    _hasChanges = true;
                  });
                },
              ),

              // Security Notifications Section
              _buildSectionHeader('SECURITY NOTIFICATIONS'),

              // New Device Alerts
              _buildSwitchTile(
                title: 'New Device Alerts',
                subtitle: 'Get notified when new devices are added',
                icon: Icons.devices_other,
                value: _newDeviceAlerts,
                onChanged: (value) {
                  setState(() {
                    _newDeviceAlerts = value;
                    _hasChanges = true;
                  });
                },
              ),

              // Security Alerts
              _buildSwitchTile(
                title: 'Security Alerts',
                subtitle: 'Receive alerts about security issues',
                icon: Icons.security,
                value: _securityAlerts,
                onChanged: (value) {
                  setState(() {
                    _securityAlerts = value;
                    _hasChanges = true;
                  });
                },
              ),

              // Marketing Section
              _buildSectionHeader('MARKETING'),

              // Marketing Emails
              _buildSwitchTile(
                title: 'Marketing Emails',
                subtitle: 'Receive updates about new features and promotions',
                icon: Icons.local_offer,
                value: _marketingEmails,
                onChanged: (value) {
                  setState(() {
                    _marketingEmails = value;
                    _hasChanges = true;
                  });
                },
              ),

              // Divider and Notification Samples Section
              const Divider(height: 32),
              _buildSectionHeader('NOTIFICATION SAMPLES'),

              // Sample Notifications
              _buildNotificationSample(
                title: 'Critical Security Alert',
                body: 'Your Smart Camera has a critical vulnerability that requires immediate action.',
                time: '2 hours ago',
                icon: Icons.security,
                iconColor: AppColors.error,
              ),

              _buildNotificationSample(
                title: 'New Device Added',
                body: 'Smart Thermostat has been added to your network.',
                time: '1 day ago',
                icon: Icons.devices,
                iconColor: AppColors.info,
              ),

              _buildNotificationSample(
                title: 'Weekly Security Report',
                body: 'Your weekly security report is ready. 3 issues found.',
                time: '3 days ago',
                icon: Icons.assessment,
                iconColor: AppColors.warning,
              ),

              // Save Button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: AppButton(
                  label: 'Save Changes',
                  onPressed: _hasChanges ? _saveSettings : null,
                  isLoading: _isLoading,
                  expanded: true,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 16.0,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary),
      ),
      title: Text(title, style: AppTextStyles.subtitle),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }

  Widget _buildNotificationSample({
    required String title,
    required String body,
    required String time,
    required IconData icon,
    required Color iconColor,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppSpacing.medium),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(title, style: AppTextStyles.subtitle),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              body,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              time,
              style: TextStyle(
                color: AppColors.textDisabled,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}