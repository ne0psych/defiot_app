import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';
import '../../core/constants/app_constants.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({Key? key}) : super(key: key);

  @override
  _AppSettingsScreenState createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  bool _isLoading = false;

  // Local state to track changes
  late String _theme;
  late String _language;
  late bool _autoUpdate;
  late bool _developerMode;
  late bool _analyticsEnabled;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _initializeSettings();
  }

  void _initializeSettings() {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _theme = settingsProvider.theme;
    _language = settingsProvider.language;
    _autoUpdate = settingsProvider.autoUpdate;
    _developerMode = settingsProvider.developerMode;
    _analyticsEnabled = settingsProvider.analyticsEnabled;
    _isDarkMode = _theme == 'dark';
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

      // Update the theme based on dark mode toggle
      _theme = _isDarkMode ? 'dark' : 'light';

      await settingsProvider.updateAppSettings(
        theme: _theme,
        language: _language,
        autoUpdate: _autoUpdate,
        developerMode: _developerMode,
        analyticsEnabled: _analyticsEnabled,
      );

      if (mounted) {
        if (settingsProvider.error != null) {
          _showErrorSnackBar(settingsProvider.error!);
        } else {
          _showSuccessSnackBar('App settings updated successfully');
        }
      }
    } catch (e) {
      _showErrorSnackBar(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _resetSettings() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text('This will reset all app settings to default values. Your devices and reports will not be affected.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Reset Settings',
              style: TextStyle(color: Colors.red[700]),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _theme = 'system';
        _isDarkMode = false;
        _language = 'english';
        _autoUpdate = true;
        _developerMode = false;
        _analyticsEnabled = true;
      });

      _saveSettings();
    }
  }

  Future<void> _clearCache() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear App Cache'),
        content: const Text('This will clear temporary app data. Your devices, reports, and settings will not be affected.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear Cache'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Show loading indicator
      setState(() {
        _isLoading = true;
      });

      try {
        // Simulate cache clearing
        await Future.delayed(const Duration(seconds: 1));

        // TODO: Implement actual cache clearing logic

        _showSuccessSnackBar('Cache cleared successfully');
      } catch (e) {
        _showErrorSnackBar('Failed to clear cache: ${e.toString()}');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Settings'),
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
            onPressed: _saveSettings,
            tooltip: 'Save Changes',
          ),
        ],
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, _) {
          return _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildAppearanceSection(),
              const SizedBox(height: 16),
              _buildLanguageSection(),
              const SizedBox(height: 16),
              _buildUpdateSection(),
              const SizedBox(height: 16),
              _buildAdvancedSection(),
              const SizedBox(height: 16),
              _buildDataManagementSection(),
              const SizedBox(height: 24),

              // Save Button
              AppButton(
                onPressed: _saveSettings,
                isLoading: _isLoading,
                label: 'Save Changes',
                icon: Icons.save,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppearanceSection() {
    return AppCard(
      title: 'Appearance',
      icon: Icons.palette,
      content: Column(
        children: [
          _buildSwitchTile(
            title: 'Dark Mode',
            subtitle: 'Enable dark theme for the app',
            icon: Icons.dark_mode,
            value: _isDarkMode,
            onChanged: (value) {
              setState(() {
                _isDarkMode = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSection() {
    return AppCard(
      title: 'Language',
      icon: Icons.language,
      content: Column(
        children: [
          DropdownButtonFormField<String>(
            value: _language,
            decoration: const InputDecoration(
              labelText: 'App Language',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            items: AppConstants.languageOptions
                .map((language) => DropdownMenuItem(
              value: language.value,
              child: Text(language.label),
            ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _language = value;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateSection() {
    return AppCard(
      title: 'Updates & Data',
      icon: Icons.system_update,
      content: Column(
        children: [
          _buildSwitchTile(
            title: 'Automatic Updates',
            subtitle: 'Automatically download and install updates',
            icon: Icons.update,
            value: _autoUpdate,
            onChanged: (value) {
              setState(() {
                _autoUpdate = value;
              });
            },
          ),
          _buildSwitchTile(
            title: 'Analytics',
            subtitle: 'Help improve the app by sending anonymous usage data',
            icon: Icons.analytics,
            value: _analyticsEnabled,
            onChanged: (value) {
              setState(() {
                _analyticsEnabled = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedSection() {
    return AppCard(
      title: 'Advanced',
      icon: Icons.code,
      content: Column(
        children: [
          _buildSwitchTile(
            title: 'Developer Mode',
            subtitle: 'Enable advanced features and debugging options',
            icon: Icons.developer_mode,
            value: _developerMode,
            onChanged: (value) {
              setState(() {
                _developerMode = value;
              });

              if (value) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Developer Mode'),
                    content: const Text(
                      'Developer mode enables advanced features and debugging options that may affect app performance or stability. Use with caution.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          setState(() {
                            _developerMode = false;
                          });
                        },
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Enable Anyway'),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDataManagementSection() {
    return AppCard(
      title: 'Data Management',
      icon: Icons.storage,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppButton(
            onPressed: _clearCache,
            label: 'Clear App Cache',
            icon: Icons.cleaning_services,
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          AppButton(
            onPressed: () {
              // TODO: Implement data export logic
              _showSuccessSnackBar('Data export coming soon');
            },
            label: 'Export All Data',
            icon: Icons.download,
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          AppButton(
            onPressed: _resetSettings,
            label: 'Reset All Settings',
            icon: Icons.restore,
            color: Colors.red,
          ),
        ],
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
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).primaryColor,
      ),
    );
  }
}