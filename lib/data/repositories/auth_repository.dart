import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../local/shared_prefs.dart';
import '../../core/exceptions/app_exceptions.dart';
import '../../core/exceptions/error_handler.dart';
import '../../models/user_model.dart';
import '../../core/constants/app_constants.dart';

/// Repository class that handles authentication operations
class AuthRepository {
  final http.Client _client;
  final String _baseUrl;

  AuthRepository({
    http.Client? client,
    String? baseUrl,
  }) :
        _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConstants.apiBaseUrl;

  /// Login with email and password
  Future<User> login(String email, String password) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/auth/token'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'username': email,
          'password': password,
          'grant_type': 'password',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw ErrorHandler.handleHttpResponse(response);
      }

      final responseBody = jsonDecode(response.body);
      final token = responseBody['access_token'];
      final refreshToken = responseBody['refresh_token'] ?? '';

      // Save auth tokens to shared preferences
      await SharedPrefs.saveAuthData(token, refreshToken);

      // Get user details using the new token
      final user = await getCurrentUser(token);

      // Save user data to shared preferences
      await SharedPrefs.saveUserData(user.toJson());

      return user;
    } catch (e) {
      if (e is http.ClientException) {
        throw NetworkException(message: 'Login failed. Please check your connection.');
      } else if (e is TimeoutException) {
        throw TimeoutException(message: 'Login request timed out. Please try again.');
      }

      // Rethrow if it's already an AppException, otherwise wrap it
      if (e is AppException) {
        rethrow;
      }
      throw AuthException(
        message: 'Login failed: ${e.toString()}',
        exception: e,
      );
    }
  }

  /// Register a new user
  Future<User> register({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
    Map<String, dynamic>? additionalInfo,
  }) async {
    try {
      final body = {
        'email': email,
        'password': password,
        'full_name': fullName,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (additionalInfo != null) ...additionalInfo,
      };

      final response = await _client.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ErrorHandler.handleHttpResponse(response);
      }

      // After successful registration, log the user in
      return await login(email, password);
    } catch (e) {
      if (e is http.ClientException) {
        throw NetworkException(message: 'Registration failed. Please check your connection.');
      } else if (e is TimeoutException) {
        throw TimeoutException(message: 'Registration request timed out. Please try again.');
      }

      // Rethrow if it's already an AppException, otherwise wrap it
      if (e is AppException) {
        rethrow;
      }
      throw AuthException(
        message: 'Registration failed: ${e.toString()}',
        exception: e,
      );
    }
  }

  /// Logout current user
  Future<void> logout() async {
    try {
      final token = SharedPrefs.getAuthToken();
      if (token == null) return;

      await _client.post(
        Uri.parse('$_baseUrl/auth/logout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 5));

      // Clear local auth data regardless of server response
      await SharedPrefs.clearAuthData();
    } catch (e) {
      // Still clear local auth data even if server logout fails
      await SharedPrefs.clearAuthData();

      // Log error but don't throw exception
      ErrorHandler.logError(e);
    }
  }

  /// Refresh the access token using refresh token
  Future<String> refreshToken() async {
    try {
      final refreshToken = SharedPrefs.getRefreshToken();
      if (refreshToken == null) {
        throw AuthException(message: 'No refresh token available');
      }

      final response = await _client.post(
        Uri.parse('$_baseUrl/auth/refresh'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'refresh_token': refreshToken}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw ErrorHandler.handleHttpResponse(response);
      }

      final responseBody = jsonDecode(response.body);
      final newToken = responseBody['access_token'];
      final newRefreshToken = responseBody['refresh_token'] ?? refreshToken;

      // Save new tokens
      await SharedPrefs.saveAuthData(newToken, newRefreshToken);

      return newToken;
    } catch (e) {
      // Token refresh failed - clear auth data and force re-login
      await SharedPrefs.clearAuthData();

      if (e is http.ClientException) {
        throw NetworkException(message: 'Token refresh failed. Please check your connection.');
      } else if (e is TimeoutException) {
        throw TimeoutException(message: 'Token refresh timed out. Please try again.');
      }

      // Rethrow if it's already an AppException, otherwise wrap it
      if (e is AppException) {
        rethrow;
      }
      throw AuthException(
        message: 'Token refresh failed: ${e.toString()}',
        exception: e,
      );
    }
  }

  /// Get current user information
  Future<User> getCurrentUser([String? token]) async {
    try {
      final authToken = token ?? SharedPrefs.getAuthToken();
      if (authToken == null) {
        throw AuthException(message: 'Not authenticated');
      }

      final response = await _client.get(
        Uri.parse('$_baseUrl/auth/users/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw ErrorHandler.handleHttpResponse(response);
      }

      final userData = jsonDecode(response.body);
      return User.fromJson(userData);
    } catch (e) {
      if (e is http.ClientException) {
        throw NetworkException(message: 'Failed to get user data. Please check your connection.');
      } else if (e is TimeoutException) {
        throw TimeoutException(message: 'Request timed out. Please try again.');
      }

      // Rethrow if it's already an AppException, otherwise wrap it
      if (e is AppException) {
        rethrow;
      }
      throw AuthException(
        message: 'Failed to get user data: ${e.toString()}',
        exception: e,
      );
    }
  }

  /// Update user profile
  Future<User> updateProfile({
    required String fullName,
    String? email,
    String? phoneNumber,
    String? profilePicture,
    String? organization,
  }) async {
    try {
      final token = SharedPrefs.getAuthToken();
      if (token == null) {
        throw AuthException(message: 'Not authenticated');
      }

      final updateData = {
        'full_name': fullName,
        if (email != null) 'email': email,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (profilePicture != null) 'profile_picture': profilePicture,
        if (organization != null) 'organization': organization,
      };

      final response = await _client.patch(
        Uri.parse('$_baseUrl/auth/users/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(updateData),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw ErrorHandler.handleHttpResponse(response);
      }

      final userData = jsonDecode(response.body);
      final user = User.fromJson(userData);

      // Update cached user data
      await SharedPrefs.saveUserData(user.toJson());

      return user;
    } catch (e) {
      if (e is http.ClientException) {
        throw NetworkException(message: 'Failed to update profile. Please check your connection.');
      } else if (e is TimeoutException) {
        throw TimeoutException(message: 'Profile update timed out. Please try again.');
      }

      // Rethrow if it's already an AppException, otherwise wrap it
      if (e is AppException) {
        rethrow;
      }
      throw AuthException(
        message: 'Failed to update profile: ${e.toString()}',
        exception: e,
      );
    }
  }

  /// Change user password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final token = SharedPrefs.getAuthToken();
      if (token == null) {
        throw AuthException(message: 'Not authenticated');
      }

      final response = await _client.post(
        Uri.parse('$_baseUrl/auth/users/me/password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw ErrorHandler.handleHttpResponse(response);
      }
    } catch (e) {
      if (e is http.ClientException) {
        throw NetworkException(message: 'Failed to change password. Please check your connection.');
      } else if (e is TimeoutException) {
        throw TimeoutException(message: 'Password change timed out. Please try again.');
      }

      // Rethrow if it's already an AppException, otherwise wrap it
      if (e is AppException) {
        rethrow;
      }
      throw AuthException(
        message: 'Failed to change password: ${e.toString()}',
        exception: e,
      );
    }
  }

  /// Request password reset
  Future<void> requestPasswordReset(String email) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/auth/password-reset'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'email': email}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw ErrorHandler.handleHttpResponse(response);
      }
    } catch (e) {
      if (e is http.ClientException) {
        throw NetworkException(message: 'Failed to request password reset. Please check your connection.');
      } else if (e is TimeoutException) {
        throw TimeoutException(message: 'Password reset request timed out. Please try again.');
      }

      // Rethrow if it's already an AppException, otherwise wrap it
      if (e is AppException) {
        rethrow;
      }
      throw AuthException(
        message: 'Failed to request password reset: ${e.toString()}',
        exception: e,
      );
    }
  }

  /// Reset password with token
  Future<void> resetPassword(String token, String newPassword) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/auth/password-reset/confirm'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'token': token,
          'new_password': newPassword,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw ErrorHandler.handleHttpResponse(response);
      }
    } catch (e) {
      if (e is http.ClientException) {
        throw NetworkException(message: 'Failed to reset password. Please check your connection.');
      } else if (e is TimeoutException) {
        throw TimeoutException(message: 'Password reset timed out. Please try again.');
      }

      // Rethrow if it's already an AppException, otherwise wrap it
      if (e is AppException) {
        rethrow;
      }
      throw AuthException(
        message: 'Failed to reset password: ${e.toString()}',
        exception: e,
      );
    }
  }

  /// Check if user is authenticated
  bool isAuthenticated() {
    return SharedPrefs.getAuthToken() != null;
  }
}