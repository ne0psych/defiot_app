// lib/screens/settings/security_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/settings_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/loading_indicator.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({Key? key}) : super(key: key);

  @override
  _SecuritySettingsScreenState createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool _isLoading = false;

  // Local state to track changes
  late bool _twoFactorAuth;
  late bool _loginAlerts;
  late String _apiKeyExpiry;
  late bool _biometricAuth;
  bool _hasChanges = false;

  final List<DropdownMenuItem<String>> _apiKeyExpiryOptions = [
    const DropdownMenuItem(value: '30days', child: Text('30 days')),
    const DropdownMenuItem(value: '60days', child: Text('60 days')),
    const DropdownMenuItem(value: '90days', child: Text('90 days')),
    const DropdownMenuItem(value: 'never', child: Text('No expiry (Not recommended)')),
  ];

  @override
  void initState() {
    super.initState();
    _initializeSettings();
  }

  void _initializeSettings() {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _twoFactorAuth = settingsProvider.twoFactorAuth;
    _loginAlerts = settingsProvider.loginAlerts;
    _apiKeyExpiry = settingsProvider.apiKeyExpiry;
    _biometricAuth = settingsProvider.biometricAuth;
  }

  Future<void> _saveSettings() async {
    if (!_hasChanges) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

      await settingsProvider.updateSecuritySettings(
        twoFactorAuth: _twoFactorAuth,
        loginAlerts: _loginAlerts,
        apiKeyExpiry: _apiKeyExpiry,
        biometricAuth: _biometricAuth,
      );

      if (mounted) {
        if (settingsProvider.error != null) {
          _showErrorSnackBar(settingsProvider.error!);
        } else {
          _showSuccessSnackBar('Security settings updated successfully');
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

  Future<void> _setupTwoFactor() async {
    // This would typically show a QR code and verification step
    // For now, we'll just show a dialog explaining the process
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Two-Factor Authentication', style: AppTextStyles.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'To enable two-factor authentication:',
                style: AppTextStyles.subtitle,
              ),
              const SizedBox(height: 16),
              _buildSetupStep(
                  number: 1,
                  text: 'Install an authenticator app (like Google Authenticator)'
              ),
              _buildSetupStep(
                  number: 2,
                  text: 'Scan the QR code that would appear here'
              ),
              _buildSetupStep(
                  number: 3,
                  text: 'Enter the verification code from the app'
              ),

              const SizedBox(height: 16),

              // QR Code Placeholder
              Center(
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(AppRadius.small),
                  ),
                  child: Icon(
                    Icons.qr_code_2,
                    size: 100,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _twoFactorAuth = false; // Reset since setup was canceled
                  _hasChanges = true;
                });
              },
              child: const Text('Cancel'),
            ),
            AppButton(
              label: 'Set Up Later',
              onPressed: () {
                Navigator.of(context).pop();
                // In a real implementation, we would verify the code here
                _saveSettings();
              },
              buttonType: AppButtonType.primary,
            ),
          ],
        ),
      );
    }
  }

  Widget _buildSetupStep({required int number, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: AppTextStyles.body),
          ),
        ],
      ),
    );
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
        title: const Text('Security Settings'),
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
              // Authentication Section
              _buildSectionHeader('AUTHENTICATION'),

              // Two-factor Authentication
              _buildSwitchTile(
                title: 'Two-Factor Authentication',
                subtitle: 'Add an extra layer of security to your account',
                icon: Icons.security,
                value: _twoFactorAuth,
                onChanged: (value) {
                  setState(() {
                    _twoFactorAuth = value;
                    _hasChanges = true;
                  });

                  if (value) {
                    _setupTwoFactor();
                  }
                },
              ),

              // Biometric Authentication
              _buildSwitchTile(
                title: 'Biometric Authentication',
                subtitle: 'Sign in using fingerprint or facial recognition',
                icon: Icons.fingerprint,
                value: _biometricAuth,
                onChanged: (value) {
                  setState(() {
                    _biometricAuth = value;
                    _hasChanges = true;
                  });
                },
              ),

              // Login Notifications
              _buildSwitchTile(
                title: 'Login Alerts',
                subtitle: 'Get notified of new logins to your account',
                icon: Icons.login,
                value: _loginAlerts,
                onChanged: (value) {
                  setState(() {
                    _loginAlerts = value;
                    _hasChanges = true;
                  });
                },
              ),

              // API Keys Section
              _buildSectionHeader('API KEYS'),

              // API Key Expiry Setting
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.key, color: AppColors.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'API Key Expiration',
                            style: AppTextStyles.subtitle,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Set how long API keys are valid before requiring renewal',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _apiKeyExpiry,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.small),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium),
                            ),
                            items: _apiKeyExpiryOptions,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _apiKeyExpiry = value;
                                  _hasChanges = true;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Current API Keys List (Preview)
              _buildApiKeysList(),

              // Password Section
              _buildSectionHeader('PASSWORD'),

              // Change Password Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: AppButton(
                  label: 'Change Password',
                  icon: Icons.lock_outline,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChangePasswordScreen(),
                      ),
                    );
                  },
                  buttonType: AppButtonType.secondary,
                  expanded: true,
                ),
              ),

              // Security Audit Card
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.security, color: AppColors.info),
                            const SizedBox(width: 8),
                            Text(
                              'Security Audit',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.info,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Regular security audits help protect your devices and data from threats.',
                        ),
                        const SizedBox(height: 16),
                        AppButton(
                          label: 'Run Security Audit',
                          onPressed: () {
                            // Navigate to scan all devices
                            Navigator.pushNamed(context, '/scan');
                          },
                          buttonType: AppButtonType.primary,
                          expanded: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Security Recommendations
              _buildSectionHeader('RECOMMENDATIONS'),
              _buildSecurityRecommendation(
                icon: Icons.password,
                title: 'Use a strong password',
                description: 'Make sure your password is at least 12 characters with a mix of letters, numbers, and symbols.',
                actionText: 'Change Password',
                onAction: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChangePasswordScreen(),
                    ),
                  );
                },
              ),
              _buildSecurityRecommendation(
                icon: Icons.security,
                title: 'Enable two-factor authentication',
                description: 'Add an extra layer of security to your account by requiring a verification code.',
                actionText: 'Enable',
                onAction: () {
                  setState(() {
                    _twoFactorAuth = true;
                    _hasChanges = true;
                  });
                  _setupTwoFactor();
                },
                isHighlighted: !_twoFactorAuth,
              ),

              // Save Button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: AppButton(
                  label: 'Save Security Settings',
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

  Widget _buildApiKeysList() {
    // Mock API keys for demonstration
    final mockApiKeys = [
      _MockApiKey(
        name: 'Mobile App',
        expiry: DateTime.now().add(const Duration(days: 25)),
        lastUsed: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      _MockApiKey(
        name: 'Web Dashboard',
        expiry: DateTime.now().add(const Duration(days: 58)),
        lastUsed: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Current API Keys', style: AppTextStyles.subtitle),
              TextButton(
                onPressed: () {
                  // Navigate to full API keys management screen
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...mockApiKeys.map((key) => _buildApiKeyItem(key)).toList(),
        ],
      ),
    );
  }

  Widget _buildApiKeyItem(_MockApiKey key) {
    final daysLeft = key.expiry.difference(DateTime.now()).inDays;
    final daysLeftColor = daysLeft < 7 ? AppColors.error :
    daysLeft < 30 ? AppColors.warning :
    AppColors.success;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.vpn_key, color: AppColors.secondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(key.name, style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    'Last used ${_formatTimeAgo(key.lastUsed)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: daysLeftColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$daysLeft days left',
                style: TextStyle(
                  color: daysLeftColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityRecommendation({
    required IconData icon,
    required String title,
    required String description,
    required String actionText,
    required VoidCallback onAction,
    bool isHighlighted = false,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        side: isHighlighted
            ? BorderSide(color: AppColors.warning, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isHighlighted
                        ? AppColors.warning.withOpacity(0.1)
                        : AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: isHighlighted ? AppColors.warning : AppColors.info,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.subtitle.copyWith(
                      color: isHighlighted ? AppColors.warning : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  foregroundColor: isHighlighted ? AppColors.warning : AppColors.primary,
                ),
                child: Text(actionText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime time) {
    final difference = DateTime.now().difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'just now';
    }
  }
}

// Mock API Key for demonstration
class _MockApiKey {
  final String name;
  final DateTime expiry;
  final DateTime lastUsed;

  _MockApiKey({
    required this.name,
    required this.expiry,
    required this.lastUsed,
  });
}

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final settingsService = Provider.of<SettingsService>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (authProvider.authToken == null) {
        throw Exception('Not authenticated');
      }

      await settingsService.changePassword(
        authProvider.authToken!,
        _currentPasswordController.text,
        _newPasswordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.onSuccess),
                const SizedBox(width: AppSpacing.small),
                const Expanded(child: Text('Password changed successfully')),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
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
        title: const Text('Change Password'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current Password
              TextFormField(
                controller: _currentPasswordController,
                obscureText: _obscureCurrentPassword,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.small),
                  ),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureCurrentPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureCurrentPassword = !_obscureCurrentPassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your current password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // New Password
              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNewPassword,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.small),
                  ),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNewPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureNewPassword = !_obscureNewPassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a new password';
                  }
                  if (value.length < 8) {
                    return 'Password must be at least 8 characters long';
                  }
                  if (!RegExp(r'[A-Z]').hasMatch(value)) {
                    return 'Password must contain at least one uppercase letter';
                  }
                  if (!RegExp(r'[a-z]').hasMatch(value)) {
                    return 'Password must contain at least one lowercase letter';
                  }
                  if (!RegExp(r'[0-9]').hasMatch(value)) {
                    return 'Password must contain at least one number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Confirm New Password
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.small),
                  ),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your new password';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Password Strength Indicator
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.small),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Password must contain:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _buildPasswordRequirement(
                      'At least 8 characters',
                      _newPasswordController.text.length >= 8,
                    ),
                    _buildPasswordRequirement(
                      'At least one uppercase letter',
                      RegExp(r'[A-Z]').hasMatch(_newPasswordController.text),
                    ),
                    _buildPasswordRequirement(
                      'At least one lowercase letter',
                      RegExp(r'[a-z]').hasMatch(_newPasswordController.text),
                    ),
                    _buildPasswordRequirement(
                      'At least one number',
                      RegExp(r'[0-9]').hasMatch(_newPasswordController.text),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Error Message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.small),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: AppColors.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),

              if (_errorMessage != null) const SizedBox(height: 24),

              // Submit Button
              AppButton(
                label: 'Change Password',
                onPressed: _isLoading ? null : _changePassword,
                isLoading: _isLoading,
                expanded: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordRequirement(String requirement, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: isMet ? AppColors.success : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            requirement,
            style: TextStyle(
              color: isMet ? AppColors.textPrimary : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}