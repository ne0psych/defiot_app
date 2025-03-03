// lib/providers/auth_provider.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/exceptions/app_exceptions.dart';
import '../services/auth_service.dart';
import '../services/http/token_interceptor.dart';

enum AuthState {
  initial,
  authenticated,
  unauthenticated,
}

class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  final TokenInterceptor _tokenInterceptor;

  AuthState _authState = AuthState.initial;
  String? _currentUser;
  String? _authToken;
  Map<String, dynamic>? _userData;
  bool _isLoading = false;
  String? _error;
  Timer? _tokenRefreshTimer;
  bool _isInitialized = false;

  AuthProvider({
    required AuthService authService,
    TokenInterceptor? tokenInterceptor,
  }) :
        _authService = authService,
        _tokenInterceptor = tokenInterceptor ?? TokenInterceptor() {
    _initializeAuthState();
  }

  // Getters
  AuthState get authState => _authState;
  bool get isAuthenticated => _authState == AuthState.authenticated;
  String? get currentUser => _currentUser;
  String? get authToken => _authToken;
  Map<String, dynamic>? get userData => _userData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;

  Future<void> _initializeAuthState() async {
    _setLoading(true);

    try {
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString('authToken');
      _currentUser = prefs.getString('currentUser');
      final userDataStr = prefs.getString('userData');

      if (userDataStr != null) {
        _userData = Map<String, dynamic>.from(jsonDecode(userDataStr));
      }

      _authState = _authToken != null ? AuthState.authenticated : AuthState.unauthenticated;

      if (_authState == AuthState.authenticated) {
        try {
          _userData = await _authService.getCurrentUser(_authToken);
          await _persistUserData(_userData!);
          _setupTokenRefresh();
        } catch (e) {
          if (kDebugMode) {
            print('Error verifying token: $e');
          }
          await logout();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing auth state: $e');
      }
      _error = 'Failed to initialize authentication';
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _persistAuthState(String token, String email, Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('authToken', token);
      await prefs.setString('currentUser', email);
      await _persistUserData(userData);

      _authToken = token;
      _currentUser = email;
      _userData = userData;
      _authState = AuthState.authenticated;

      _setupTokenRefresh();
    } catch (e) {
      if (kDebugMode) {
        print('Error saving auth state: $e');
      }
      rethrow;
    }
  }

  Future<void> updateUserData(Map<String, dynamic> newData) async {
    if (_userData == null) {
      _userData = {};
    }
    _userData!.addAll(newData);
    await _persistUserData(_userData!);
    notifyListeners();
  }

  Future<void> _persistUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userData', jsonEncode(userData));
    } catch (e) {
      if (kDebugMode) {
        print('Error saving user data: $e');
      }
    }
  }

  void _setupTokenRefresh() {
    _tokenRefreshTimer?.cancel();

    // Refresh token 5 minutes before expiry
    const refreshInterval = Duration(minutes: 55);
    _tokenRefreshTimer = Timer.periodic(refreshInterval, (timer) {
      if (_authState == AuthState.authenticated) {
        refreshToken();
      }
    });
  }

  Future<void> login(String email, String password) async {
    if (_isLoading) return;

    _setLoading(true);
    _error = null;

    try {
      final response = await _authService.login(email, password);

      if (response != null) {
        final token = response['access_token'];
        final userData = response['user'];

        if (token != null && userData != null) {
          await _persistAuthState(token, email, userData);
          _error = null;
          _authState = AuthState.authenticated;
        } else {
          throw Exception('Invalid response data');
        }
      } else {
        throw Exception('Login failed');
      }
    } catch (e) {
      _authState = AuthState.unauthenticated;
      _error = _formatError(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
    Map<String, dynamic>? additionalInfo,
  }) async {
    if (_isLoading) return;

    _setLoading(true);
    _error = null;

    try {
      final response = await _authService.register(
        email: email,
        password: password,
        fullName: fullName,
        phoneNumber: phoneNumber,
        additionalInfo: additionalInfo,
      );

      if (response != null) {
        // Automatically login after successful registration
        await login(email, password);
      }
    } catch (e) {
      _error = _formatError(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);

    try {
      await _authService.logout();

      _tokenRefreshTimer?.cancel();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      _authToken = null;
      _currentUser = null;
      _userData = null;
      _authState = AuthState.unauthenticated;
      _error = null;
    } catch (e) {
      if (kDebugMode) {
        print('Error during logout: $e');
      }
      // Continue with local logout even if server logout fails
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshToken() async {
    try {
      if (_authState != AuthState.authenticated || _authToken == null) return;

      // Get the refresh token from secure storage
      // This is a simplified version - in a real app you'd securely store the refresh token
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refreshToken');

      if (refreshToken != null) {
        final response = await _authService.refreshToken(refreshToken);
        if (response != null) {
          final newToken = response['access_token'];
          if (newToken != null) {
            _authToken = newToken;
            await _tokenInterceptor.saveToken(newToken);

            // Save the new refresh token if provided
            if (response['refresh_token'] != null) {
              await prefs.setString('refreshToken', response['refresh_token']);
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error refreshing token: $e');
      }
      // If token refresh fails, log the user out
      await logout();
    }
  }

  Future<void> updateProfile({
    String? fullName,
    String? phoneNumber,
    Map<String, dynamic>? preferences,
  }) async {
    if (_authState != AuthState.authenticated) {
      throw UnauthorizedException('Not authenticated');
    }

    _setLoading(true);

    try {
      final updatedUserData = await _authService.updateUserProfile(
        fullName: fullName,
        phoneNumber: phoneNumber,
        preferences: preferences,
      );

      _userData = updatedUserData;
      await _persistUserData(updatedUserData);
      _error = null;
    } catch (e) {
      _error = _formatError(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    if (_authState != AuthState.authenticated) {
      throw UnauthorizedException('Not authenticated');
    }

    _setLoading(true);

    try {
      await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      _error = null;
    } catch (e) {
      _error = _formatError(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> requestPasswordReset(String email) async {
    _setLoading(true);

    try {
      await _authService.requestPasswordReset(email);
      _error = null;
    } catch (e) {
      _error = _formatError(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> resetPassword(String token, String newPassword) async {
    _setLoading(true);

    try {
      await _authService.resetPassword(token, newPassword);
      _error = null;
    } catch (e) {
      _error = _formatError(e);
      rethrow;
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

  @override
  void dispose() {
    _tokenRefreshTimer?.cancel();
    super.dispose();
  }
}