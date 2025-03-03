import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../local/shared_prefs.dart';
import '../../core/exceptions/app_exceptions.dart';
import '../../core/exceptions/error_handler.dart';
import '../../models/settings_model.dart';
import '../../core/constants/app_constants.dart';

/// Repository class that handles settings operations
class SettingsRepository {
  final http.Client _client;
  final String _baseUrl;

  SettingsRepository({
    http.Client? client,
    String? baseUrl,
  }) :
        _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConstants.apiBaseUrl;

  /// Helper method to get the auth headers
  Future<Map<String, String>> _getHeaders() async {
    final token = SharedPrefs.getAuthToken();
    if (token == null) {
      throw AuthException(message: 'Not authenticated');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Get all settings
  Future<Map<String, dynamic>> getSettings() async {
    try {
      // Check if we have cached settings
      final cachedSettings = SharedPrefs.getSettings();
      if (cachedSettings.isNotEmpty) {
        return cachedSettings;
      }

      final response = await _client.get(
        Uri.parse('$_baseUrl/settings'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw ErrorHandler.handleHttpResponse(response);
      }

      final settings = jsonDecode(response.body);

      // Cache settings
      await SharedPrefs.saveSettings(settings);

      return settings;
    } catch (e) {
      if (e is http.ClientException) {
        // If there's a network error, return default settings
        return AppConstants.defaultSettings;
      } else if (e is TimeoutException) {
        // If there's a timeout, return default settings
        return AppConstants.defaultSettings;
      }

      if (e is AppException) {
        // Return default settings for any app exception
        return AppConstants.defaultSettings;
      }

      // Log the error but return default settings
      ErrorHandler.logError(e);
      return AppConstants.defaultSettings;
    }
  }

  /// Update notification settings
  Future<Map<String, dynamic>> updateNotificationSettings(
      NotificationSettings settings,
      ) async {
    try {
      final response = await _client.put(
        Uri.parse('$_baseUrl/settings/notifications'),
        headers: await _getHeaders(),
        body: jsonEncode(settings.toJson()),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw ErrorHandler.handleHttpResponse(response);
      }

      final updatedSettings = jsonDecode(response.body);

      // Update settings in cache
      final cachedSettings = SharedPrefs.getSettings();
      cachedSettings['notifications'] = updatedSettings;
      await SharedPrefs.saveSettings(cachedSettings);

      // Also save notifications separately for quick access
      await SharedPrefs.saveNotificationSettings(updatedSettings);

      return updatedSettings;
    } catch (e) {
      if (e is http.ClientException) {
        throw NetworkException(message: 'Failed to update notifications. Please check your connection.');
      } else if (e is TimeoutException) {
        throw TimeoutException(message: 'Settings update timed out. Please try again.');
      }

      if (e is AppException) {
        rethrow;
      }
      throw Exception('Failed to update notification settings: ${e.toString()}');
    }
  }

  /// Update security settings
  Future<Map<String, dynamic>> updateSecuritySettings(
      SecuritySettings settings,
      ) async {
    try {
      final response = await _client.put(
        Uri.parse('$_baseUrl/settings/security'),
        headers: await _getHeaders(),
        body: jsonEncode(settings.toJson()),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw ErrorHandler.handleHttpResponse(response);
      }

      final updatedSettings = jsonDecode(response.body);

      // Update settings in cache
      final cachedSettings = SharedPrefs.getSettings();
      cachedSettings['security'] = updatedSettings;
      await SharedPrefs.saveSettings(cachedSettings);

      return updatedSettings;
    } catch (e) {
      if (e is http.ClientException) {
        throw NetworkException(message: 'Failed to update security settings. Please check your connection.');
      } else if (e is TimeoutException) {
        throw TimeoutException(message: 'Settings update timed out. Please try again.');
      }

      if (e is AppException) {
        rethrow;
      }
      throw Exception('Failed to update security settings: ${e.toString()}');
    }
  }

  /// Update app settings
  Future<Map<String, dynamic>> updateAppSettings(
      AppSettings settings,
      ) async {
    try {
      final response = await _client.put(
        Uri.parse('$_baseUrl/settings/app-config'),
        headers: await _getHeaders(),
        body: jsonEncode(settings.toJson()),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw ErrorHandler.handleHttpResponse(response);
      }

      final updatedSettings = jsonDecode(response.body);

      // Update settings in cache
      final cachedSettings = SharedPrefs.getSettings();
      cachedSettings['app_config'] = updatedSettings;
      await SharedPrefs.saveSettings(cachedSettings);

      // Save theme and language settings separately for quick access
      if (updatedSettings['theme'] != null) {
        await SharedPrefs.saveTheme(updatedSettings['theme']);
      }

      if (updatedSettings['language'] != null) {
        await SharedPrefs.saveLanguage(updatedSettings['language']);
      }

      return updatedSettings;
    } catch (e) {
      if (e is http.ClientException) {
        throw NetworkException(message: 'Failed to update app settings. Please check your connection.');
      } else if (e is TimeoutException) {
        throw TimeoutException(message: 'Settings update timed out. Please try again.');
      }

      if (e is AppException) {
        rethrow;
      }
      throw Exception('Failed to update app settings: ${e.toString()}');
    }
  }

  /// Update user profile settings
  Future<Map<String, dynamic>> updateProfile({
    required String fullName,
    String? email,
    String? phoneNumber,
    String? profilePicture,
    String? organization,
    Map<String, dynamic>? additionalInfo,
  }) async {
    try {
      final profileData = {
        'full_name': fullName,
        if (email != null) 'email': email,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (profilePicture != null) 'profile_picture': profilePicture,
        if (organization != null) 'organization': organization,
        if (additionalInfo != null) ...additionalInfo,
      };

      final response = await _client.put(
        Uri.parse('$_baseUrl/settings/profile'),
        headers: await _getHeaders(),
        body: jsonEncode(profileData),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw ErrorHandler.handleHttpResponse(response);
      }

      final updatedProfile = jsonDecode(response.body);

      // Update profile in cached settings
      final cachedSettings = SharedPrefs.getSettings();
      cachedSettings['profile'] = updatedProfile;
      await SharedPrefs.saveSettings(cachedSettings);

      // Also update user data cache
      final userData = SharedPrefs.getUserData();
      if (userData != null) {
        userData['full_name'] = fullName;
        if (email != null) userData['email'] = email;
        if (phoneNumber != null) userData['phone_number'] = phoneNumber;
        if (profilePicture != null) userData['profile_picture'] = profilePicture;
        if (organization != null) userData['organization'] = organization;

        await SharedPrefs.saveUserData(userData);
      }

      return updatedProfile;
    } catch (e) {
      if (e is http.ClientException) {
        throw NetworkException(message: 'Failed to update profile. Please check your connection.');
      } else if (e is TimeoutException) {
        throw TimeoutException(message: 'Profile update timed out. Please try again.');
      }

      if (e is AppException) {
        rethrow;
      }
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }

  /// Generate a new API key
  Future<String> generateApiKey([Map<String, dynamic>? options]) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/settings/api-key'),
        headers: await _getHeaders(),
        body: options != null ? jsonEncode(options) : '{}',
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw ErrorHandler.handleHttpResponse(response);
      }

      final data = jsonDecode(response.body);
      return data['api_key'];
    } catch (e) {
      if (e is http.ClientException) {
        throw NetworkException(message: 'Failed to generate API key. Please check your connection.');
      } else if (e is TimeoutException) {
        throw TimeoutException(message: 'API key generation timed out. Please try again.');
      }

      if (e is AppException) {
        rethrow;
      }
      throw Exception('Failed to generate API key: ${e.toString()}');
    }
  }

  /// Revoke an API key
  Future<bool> revokeApiKey(String keyId) async {
    try {
      final response = await _client.delete(
        Uri.parse('$_baseUrl/settings/api-key/$keyId'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 204;
    } catch (e) {
      if (e is http.ClientException) {
        throw NetworkException(message: 'Failed to revoke API key. Please check your connection.');
      } else if (e is TimeoutException) {
        throw TimeoutException(message: 'API key revocation timed out. Please try again.');
      }

      if (e is AppException) {
        rethrow;
      }
      throw Exception('Failed to revoke API key: ${e.toString()}');
    }
  }

  /// Change user password
  Future<Map<String, dynamic>> changePassword(
      String currentPassword,
      String newPassword,
      ) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/settings/change-password'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw ErrorHandler.handleHttpResponse(response);
      }

      return jsonDecode(response.body);
    } catch (e) {
      if (e is http.ClientException) {
        throw NetworkException(message: 'Failed to change password. Please check your connection.');
      } else if (e is TimeoutException) {
        throw TimeoutException(message: 'Password change timed out. Please try again.');
      }

      if (e is AppException) {
        rethrow;
      }
      throw Exception('Failed to change password: ${e.toString()}');
    }
  }

  /// Enable two-factor authentication
  Future<bool> enableTwoFactorAuth() async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/settings/two-factor/enable'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw ErrorHandler.handleHttpResponse(response);
      }

      final data = jsonDecode(response.body);
      return data['enabled'] == true;
    } catch (e) {
      if (e is http.ClientException) {
        throw NetworkException(message: 'Failed to enable two-factor authentication. Please check your connection.');
      } else if (e is TimeoutException) {
        throw TimeoutException(message: 'Two-factor setup timed out. Please try again.');
      }

      if (e is AppException) {
        rethrow;
      }
      throw Exception('Failed to enable two-factor authentication: ${e.toString()}');
    }
  }

  /// Disable two-factor authentication
  Future<bool> disableTwoFactorAuth(String verificationCode) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/settings/two-factor/disable'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'verification_code': verificationCode,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw ErrorHandler.handleHttpResponse(response);
      }

      final data = jsonDecode(response.body);
      return data['disabled'] == true;
    } catch (e) {
      if (e is http.ClientException) {
        throw NetworkException(message: 'Failed to disable two-factor authentication. Please check your connection.');
      } else if (e is TimeoutException) {
        throw TimeoutException(message: 'Two-factor disable timed out. Please try again.');
      }

      if (e is AppException) {
        rethrow;
      }
      throw Exception('Failed to disable two-factor authentication: ${e.toString()}');
    }
  }

  /// Get app theme from local storage
  String getTheme() {
    return SharedPrefs.getTheme(defaultTheme: AppConstants.defaultTheme);
  }

  /// Get app language from local storage
  String getLanguage() {
    return SharedPrefs.getLanguage(defaultLanguage: 'english');
  }

  /// Reset all settings to default
  Future<void> resetToDefaults() async {
    try {
      // Reset on server
      final response = await _client.post(
        Uri.parse('$_baseUrl/settings/reset'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw ErrorHandler.handleHttpResponse(response);
      }

      // Reset locally
      await SharedPrefs.saveSettings(AppConstants.defaultSettings);
      await SharedPrefs.saveTheme(AppConstants.defaultTheme);
      await SharedPrefs.saveLanguage('english');
      await SharedPrefs.saveNotificationSettings({
        'push_notifications': true,
        'email_notifications': true,
        'new_device_alerts': true,
        'security_alerts': true,
        'marketing_emails': false,
      });
    } catch (e) {
      // If server reset fails, still reset locally
      await SharedPrefs.saveSettings(AppConstants.defaultSettings);
      await SharedPrefs.saveTheme(AppConstants.defaultTheme);
      await SharedPrefs.saveLanguage('english');

      if (e is http.ClientException || e is TimeoutException) {
        // Don't throw for connectivity issues
        ErrorHandler.logError(e);
      } else if (e is AppException) {
        rethrow;
      } else {
        throw Exception('Failed to reset settings: ${e.toString()}');
      }
    }
  }
}