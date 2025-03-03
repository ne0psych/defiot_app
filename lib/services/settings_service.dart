// lib/services/settings_service.dart
import 'dart:async';
import '../models/settings_model.dart';
import 'base_service.dart';
import 'http/api_client.dart';

class SettingsService extends BaseService {
  static const String _baseEndpoint = '/settings';

  SettingsService({required ApiClient apiClient}) : super(apiClient: apiClient);

  Future<Map<String, dynamic>> getSettings() async {
    return execute<Map<String, dynamic>>(
      task: () async {
        final response = await apiClient.get(_baseEndpoint);

        if (response is Map<String, dynamic>) {
          return response;
        } else {
          throw Exception('Invalid response format');
        }
      },
      errorMessage: 'Failed to load settings',
    );
  }

  Future<Map<String, dynamic>> updateNotificationSettings(Map<String, dynamic> settings) async {
    return execute<Map<String, dynamic>>(
      task: () async {
        final response = await apiClient.put(
          '$_baseEndpoint/notifications',
          body: settings,
        );

        if (response is Map<String, dynamic>) {
          return response;
        } else {
          throw Exception('Invalid response format');
        }
      },
      errorMessage: 'Failed to update notification settings',
    );
  }

  Future<Map<String, dynamic>> updateSecuritySettings(Map<String, dynamic> settings) async {
    return execute<Map<String, dynamic>>(
      task: () async {
        final response = await apiClient.put(
          '$_baseEndpoint/security',
          body: settings,
        );

        if (response is Map<String, dynamic>) {
          return response;
        } else {
          throw Exception('Invalid response format');
        }
      },
      errorMessage: 'Failed to update security settings',
    );
  }

  Future<Map<String, dynamic>> updateAppSettings(Map<String, dynamic> settings) async {
    return execute<Map<String, dynamic>>(
      task: () async {
        final response = await apiClient.put(
          '$_baseEndpoint/app-config',
          body: settings,
        );

        if (response is Map<String, dynamic>) {
          return response;
        } else {
          throw Exception('Invalid response format');
        }
      },
      errorMessage: 'Failed to update app settings',
    );
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> profile) async {
    return execute<Map<String, dynamic>>(
      task: () async {
        final response = await apiClient.put(
          '$_baseEndpoint/profile',
          body: profile,
        );

        if (response is Map<String, dynamic>) {
          return response;
        } else {
          throw Exception('Invalid response format');
        }
      },
      errorMessage: 'Failed to update profile',
    );
  }

  Future<Map<String, dynamic>> generateApiKey([Map<String, dynamic>? options]) async {
    return execute<Map<String, dynamic>>(
      task: () async {
        final body = options ?? {};

        final response = await apiClient.post(
          '$_baseEndpoint/api-key',
          body: body,
        );

        if (response is Map<String, dynamic>) {
          return response;
        } else {
          throw Exception('Invalid response format');
        }
      },
      errorMessage: 'Failed to generate API key',
    );
  }

  Future<bool> revokeApiKey(String keyId) async {
    return execute<bool>(
      task: () async {
        await apiClient.delete('$_baseEndpoint/api-key/$keyId');
        return true;
      },
      errorMessage: 'Failed to revoke API key',
    );
  }

  Future<Map<String, dynamic>> changePassword(
      String currentPassword,
      String newPassword,
      ) async {
    return execute<Map<String, dynamic>>(
      task: () async {
        final body = {
          'current_password': currentPassword,
          'new_password': newPassword,
        };

        final response = await apiClient.post(
          '$_baseEndpoint/change-password',
          body: body,
        );

        if (response is Map<String, dynamic>) {
          return response;
        } else {
          return {'message': 'Password changed successfully'};
        }
      },
      errorMessage: 'Failed to change password',
    );
  }

  Future<Map<String, dynamic>> enableTwoFactorAuth() async {
    return execute<Map<String, dynamic>>(
      task: () async {
        final response = await apiClient.post(
          '$_baseEndpoint/two-factor/enable',
        );

        if (response is Map<String, dynamic>) {
          return response;
        } else {
          throw Exception('Invalid response format');
        }
      },
      errorMessage: 'Failed to enable two-factor authentication',
    );
  }

  Future<Map<String, dynamic>> disableTwoFactorAuth(String verificationCode) async {
    return execute<Map<String, dynamic>>(
      task: () async {
        final body = {'verification_code': verificationCode};

        final response = await apiClient.post(
          '$_baseEndpoint/two-factor/disable',
          body: body,
        );

        if (response is Map<String, dynamic>) {
          return response;
        } else {
          throw Exception('Invalid response format');
        }
      },
      errorMessage: 'Failed to disable two-factor authentication',
    );
  }

  Future<Map<String, dynamic>> verifyTwoFactorAuth(String verificationCode) async {
    return execute<Map<String, dynamic>>(
      task: () async {
        final body = {'verification_code': verificationCode};

        final response = await apiClient.post(
          '$_baseEndpoint/two-factor/verify',
          body: body,
        );

        if (response is Map<String, dynamic>) {
          return response;
        } else {
          throw Exception('Invalid response format');
        }
      },
      errorMessage: 'Invalid verification code',
    );
  }

  Future<Map<String, dynamic>> regenerateBackupCodes() async {
    return execute<Map<String, dynamic>>(
      task: () async {
        final response = await apiClient.post(
          '$_baseEndpoint/two-factor/regenerate-backup-codes',
        );

        if (response is Map<String, dynamic>) {
          return response;
        } else {
          throw Exception('Invalid response format');
        }
      },
      errorMessage: 'Failed to regenerate backup codes',
    );
  }
}