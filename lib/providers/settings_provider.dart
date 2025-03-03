// lib/providers/settings_provider.dart
import 'package:flutter/foundation.dart';
import '../models/settings_model.dart';
import '../services/settings_service.dart';
import '../core/exceptions/app_exceptions.dart';
import 'auth_provider.dart';

class SettingsProvider with ChangeNotifier {
  final SettingsService _settingsService;
  final AuthProvider _authProvider;

  // Settings objects
  NotificationSettings? _notificationSettings;
  SecuritySettings? _securitySettings;
  AppSettings? _appSettings;
  UserProfile? _userProfile;
  List<ApiKeySettings> _apiKeys = [];

  bool _isLoading = false;
  String? _error;

  SettingsProvider({
    required SettingsService settingsService,
    required AuthProvider authProvider,
  })  : _settingsService = settingsService,
        _authProvider = authProvider;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Notification Settings
  NotificationSettings get notificationSettings => _notificationSettings ?? NotificationSettings();
  bool get pushNotifications => _notificationSettings?.pushNotifications ?? true;
  bool get emailNotifications => _notificationSettings?.emailNotifications ?? true;
  bool get newDeviceAlerts => _notificationSettings?.newDeviceAlerts ?? true;
  bool get securityAlerts => _notificationSettings?.securityAlerts ?? true;
  bool get marketingEmails => _notificationSettings?.marketingEmails ?? false;

  // Security Settings
  SecuritySettings get securitySettings => _securitySettings ?? SecuritySettings();
  bool get twoFactorAuth => _securitySettings?.twoFactorAuth ?? false;
  bool get loginAlerts => _securitySettings?.loginAlerts ?? true;
  String get apiKeyExpiry => _securitySettings?.apiKeyExpiry ?? '30days';
  bool get biometricAuth => _securitySettings?.biometricAuth ?? false;

  // App Settings
  AppSettings get appSettings => _appSettings ?? AppSettings();
  String get theme => _appSettings?.theme ?? 'system';
  String get language => _appSettings?.language ?? 'english';
  bool get autoUpdate => _appSettings?.autoUpdate ?? true;
  bool get developerMode => _appSettings?.developerMode ?? false;
  bool get analyticsEnabled => _appSettings?.analyticsEnabled ?? true;

  // User Profile
  UserProfile get userProfile => _userProfile ?? UserProfile(
    fullName: _authProvider.userData?['full_name'] ?? '',
    email: _authProvider.userData?['email'] ?? '',
  );

  // API Keys
  List<ApiKeySettings> get apiKeys => _apiKeys;

  Future<void> loadSettings() async {
    _setLoading(true);
    _error = null;

    try {
      final settings = await _settingsService.getSettings();

      // Parse notification settings
      if (settings['notifications'] != null) {
        _notificationSettings = NotificationSettings.fromJson(settings['notifications']);
      }

      // Parse security settings
      if (settings['security'] != null) {
        _securitySettings = SecuritySettings.fromJson(settings['security']);
      }

      // Parse app settings
      if (settings['app_config'] != null) {
        _appSettings = AppSettings.fromJson(settings['app_config']);
      }

      // Parse user profile
      if (settings['profile'] != null) {
        _userProfile = UserProfile.fromJson(settings['profile']);
      } else if (_authProvider.userData != null) {
        _userProfile = UserProfile(
          fullName: _authProvider.userData?['full_name'] ?? '',
          email: _authProvider.userData?['email'] ?? '',
          lastLogin: _authProvider.userData?['last_login'] != null
              ? DateTime.parse(_authProvider.userData!['last_login'])
              : null,
          roles: (_authProvider.userData?['roles'] as List<dynamic>?)?.map((role) => role.toString()).toList() ?? [],
        );
      }

      // Parse API keys
      if (settings['api_keys'] != null && settings['api_keys'] is List) {
        _apiKeys = (settings['api_keys'] as List)
            .map((keyData) => ApiKeySettings.fromJson(keyData))
            .toList();
      }
    } catch (e) {
      _error = _formatError(e);
      // Set defaults if loading fails
      _notificationSettings = NotificationSettings();
      _securitySettings = SecuritySettings();
      _appSettings = AppSettings();
      _apiKeys = [];
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateNotificationSettings({
    bool? pushNotifications,
    bool? emailNotifications,
    bool? newDeviceAlerts,
    bool? securityAlerts,
    bool? marketingEmails,
  }) async {
    _setLoading(true);

    try {
      final currentSettings = _notificationSettings ?? NotificationSettings();
      final updatedSettings = currentSettings.copyWith(
        pushNotifications: pushNotifications,
        emailNotifications: emailNotifications,
        newDeviceAlerts: newDeviceAlerts,
        securityAlerts: securityAlerts,
        marketingEmails: marketingEmails,
      );

      final response = await _settingsService.updateNotificationSettings(
        updatedSettings.toJson(),
      );

      _notificationSettings = NotificationSettings.fromJson(response);
      _error = null;
    } catch (e) {
      _error = _formatError(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateSecuritySettings({
    bool? twoFactorAuth,
    bool? loginAlerts,
    String? apiKeyExpiry,
    bool? biometricAuth,
  }) async {
    _setLoading(true);

    try {
      final currentSettings = _securitySettings ?? SecuritySettings();
      final updatedSettings = currentSettings.copyWith(
        twoFactorAuth: twoFactorAuth,
        loginAlerts: loginAlerts,
        apiKeyExpiry: apiKeyExpiry,
        biometricAuth: biometricAuth,
      );

      final response = await _settingsService.updateSecuritySettings(
        updatedSettings.toJson(),
      );

      _securitySettings = SecuritySettings.fromJson(response);
      _error = null;
    } catch (e) {
      _error = _formatError(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateAppSettings({
    String? theme,
    String? language,
    bool? autoUpdate,
    bool? developerMode,
    bool? analyticsEnabled,
    Map<String, dynamic>? customConfigurations,
  }) async {
    _setLoading(true);

    try {
      final currentSettings = _appSettings ?? AppSettings();
      final updatedSettings = currentSettings.copyWith(
        theme: theme,
        language: language,
        autoUpdate: autoUpdate,
        developerMode: developerMode,
        analyticsEnabled: analyticsEnabled,
        customConfigurations: customConfigurations,
      );

      final response = await _settingsService.updateAppSettings(
        updatedSettings.toJson(),
      );

      _appSettings = AppSettings.fromJson(response);
      _error = null;
    } catch (e) {
      _error = _formatError(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateProfile({
    String? fullName,
    String? email,
    String? phoneNumber,
    String? profilePicture,
  }) async {
    _setLoading(true);

    try {
      final updatedProfile = {
        if (fullName != null) 'full_name': fullName,
        if (email != null) 'email': email,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (profilePicture != null) 'profile_picture': profilePicture,
      };

      final response = await _settingsService.updateProfile(
        updatedProfile,
      );

      // Update user profile with the response
      if (_userProfile == null) {
        _userProfile = UserProfile(
          fullName: response['full_name'] ?? '',
          email: response['email'] ?? '',
        );
      } else {
        _userProfile = _userProfile!.copyWith(
          fullName: response['full_name'],
          email: response['email'],
          phoneNumber: response['phone_number'],
          profilePicture: response['profile_picture'],
        );
      }

      // Update user info in auth provider if needed
      if (email != null || fullName != null) {
        // Notify auth provider about profile changes
        _authProvider.updateUserData({
          'email': _userProfile!.email,
          'full_name': _userProfile!.fullName,
        });
      }

      _error = null;
    } catch (e) {
      _error = _formatError(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> generateApiKey({
    String? description,
    List<String>? permissions,
    int? expiryDays,
  }) async {
    _setLoading(true);

    try {
      final apiKeyData = {
        if (description != null) 'description': description,
        if (permissions != null) 'permissions': permissions,
        if (expiryDays != null) 'expiry_days': expiryDays,
      };

      final response = await _settingsService.generateApiKey(apiKeyData);

      // Update API keys list after generating new key
      await loadSettings();

      _error = null;
      return response['api_key'];
    } catch (e) {
      _error = _formatError(e);
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> revokeApiKey(String keyId) async {
    _setLoading(true);

    try {
      final success = await _settingsService.revokeApiKey(keyId);
      if (success) {
        // Remove from local list
        _apiKeys.removeWhere((key) => key.key == keyId);
        _error = null;
      }
      return success;
    } catch (e) {
      _error = _formatError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _setLoading(true);

    try {
      final response = await _settingsService.changePassword(
        currentPassword,
        newPassword,
      );
      _error = null;
      return response;
    } catch (e) {
      _error = _formatError(e);
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>?> enableTwoFactorAuth() async {
    _setLoading(true);

    try {
      final response = await _settingsService.enableTwoFactorAuth();
      _error = null;
      return response;
    } catch (e) {
      _error = _formatError(e);
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>?> disableTwoFactorAuth(String verificationCode) async {
    _setLoading(true);

    try {
      final response = await _settingsService.disableTwoFactorAuth(verificationCode);
      _error = null;
      return response;
    } catch (e) {
      _error = _formatError(e);
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>?> verifyTwoFactorAuth(String verificationCode) async {
    _setLoading(true);

    try {
      final response = await _settingsService.verifyTwoFactorAuth(verificationCode);
      _error = null;
      return response;
    } catch (e) {
      _error = _formatError(e);
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>?> regenerateBackupCodes() async {
    _setLoading(true);

    try {
      final response = await _settingsService.regenerateBackupCodes();
      _error = null;
      return response;
    } catch (e) {
      _error = _formatError(e);
      return null;
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _formatError(dynamic error) {
    if (error is ApiException) {
      return error.message;
    }

    if (error is Exception) {
      return error.toString().replaceAll('Exception: ', '');
    }

    return error.toString();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}