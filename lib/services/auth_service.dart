// lib/services/auth_service.dart
import 'dart:async';
import '../core/exceptions/app_exceptions.dart';
import 'base_service.dart';
import 'http/api_client.dart';
import 'http/token_interceptor.dart';

class AuthService extends BaseService {
  static const String _baseEndpoint = '/auth';
  final TokenInterceptor _tokenInterceptor;

  AuthService({
    required ApiClient apiClient,
    TokenInterceptor? tokenInterceptor,
  }) :
        _tokenInterceptor = tokenInterceptor ?? TokenInterceptor(),
        super(apiClient: apiClient);

  Future<Map<String, dynamic>> login(String email, String password) async {
    return execute<Map<String, dynamic>>(
      task: () async {
        // For FastAPI's OAuth2 form-based authentication
        final url = Uri.parse('${_baseEndpoint}/token');
        final headers = {
          'Content-Type': 'application/x-www-form-urlencoded',
        };
        final body = {
          'username': email,
          'password': password,
          'grant_type': 'password',
        };

        // Direct use of http client to handle form-urlencoded format
        final response = await apiClient._client.post(
          url,
          headers: headers,
          body: body,
        );

        if (response.statusCode == 200) {
          final responseData = await apiClient._handleResponse(response);

          // Get the token and save it
          final token = responseData['access_token'];
          await _tokenInterceptor.saveToken(token);

          // Get user details with the token
          final userDetails = await getCurrentUser(token);

          return {
            'access_token': token,
            'token_type': responseData['token_type'],
            'user': userDetails,
          };
        } else {
          throw await apiClient._handleResponse(response);
        }
      },
      errorMessage: 'Login failed',
    );
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
    Map<String, dynamic>? additionalInfo,
  }) async {
    return execute<Map<String, dynamic>>(
      task: () async {
        final body = {
          'email': email,
          'password': password,
          'full_name': fullName,
          if (phoneNumber != null) 'phone_number': phoneNumber,
          if (additionalInfo != null) ...additionalInfo,
        };

        final response = await apiClient.post(
          '$_baseEndpoint/register',
          body: body,
        );

        if (response is Map<String, dynamic>) {
          return response;
        } else {
          throw Exception('Invalid response format');
        }
      },
      errorMessage: 'Registration failed',
    );
  }

  Future<void> logout() async {
    return execute<void>(
      task: () async {
        final token = await _tokenInterceptor.getToken();
        if (token != null) {
          try {
            await apiClient.post('$_baseEndpoint/logout');
          } catch (e) {
            // Ignore errors on logout - just clear the token
          }
        }

        // Always clear the token
        await _tokenInterceptor.clearToken();
        return;
      },
      errorMessage: 'Logout failed',
    );
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    return execute<Map<String, dynamic>>(
      task: () async {
        final body = {'refresh_token': refreshToken};

        final response = await apiClient.post(
          '$_baseEndpoint/refresh',
          body: body,
        );

        if (response is Map<String, dynamic>) {
          // Save the new token
          final token = response['access_token'];
          await _tokenInterceptor.saveToken(token);
          return response;
        } else {
          throw Exception('Invalid response format');
        }
      },
      errorMessage: 'Token refresh failed',
    );
  }

  Future<Map<String, dynamic>> getCurrentUser([String? token]) async {
    return execute<Map<String, dynamic>>(
      task: () async {
        final response = await apiClient.get(
          '$_baseEndpoint/users/me',
          token: token,
        );

        if (response is Map<String, dynamic>) {
          return response;
        } else {
          throw Exception('Invalid response format');
        }
      },
      errorMessage: 'Failed to get user info',
    );
  }

  Future<Map<String, dynamic>> updateUserProfile({
    String? fullName,
    String? phoneNumber,
    Map<String, dynamic>? preferences,
  }) async {
    return execute<Map<String, dynamic>>(
      task: () async {
        final body = {
          if (fullName != null) 'full_name': fullName,
          if (phoneNumber != null) 'phone_number': phoneNumber,
          if (preferences != null) 'preferences': preferences,
        };

        final response = await apiClient.patch(
          '$_baseEndpoint/users/me',
          body: body,
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

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return execute<void>(
      task: () async {
        final body = {
          'current_password': currentPassword,
          'new_password': newPassword,
        };

        await apiClient.post(
          '$_baseEndpoint/users/me/password',
          body: body,
        );

        return;
      },
      errorMessage: 'Failed to change password',
    );
  }

  Future<void> requestPasswordReset(String email) async {
    return execute<void>(
      task: () async {
        final body = {'email': email};

        await apiClient.post(
          '$_baseEndpoint/password-reset',
          body: body,
        );

        return;
      },
      errorMessage: 'Failed to request password reset',
    );
  }

  Future<void> validatePasswordResetToken(String token) async {
    return execute<void>(
      task: () async {
        final body = {'token': token};

        await apiClient.post(
          '$_baseEndpoint/password-reset/validate',
          body: body,
        );

        return;
      },
      errorMessage: 'Invalid or expired reset token',
    );
  }

  Future<void> resetPassword(String token, String newPassword) async {
    return execute<void>(
      task: () async {
        final body = {
          'token': token,
          'new_password': newPassword,
        };

        await apiClient.post(
          '$_baseEndpoint/password-reset/confirm',
          body: body,
        );

        return;
      },
      errorMessage: 'Failed to reset password',
    );
  }
}