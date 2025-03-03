// lib/services/http/api_client.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../../core/exceptions/app_exceptions.dart';

class ApiClient {
  final String baseUrl;
  final http.Client client;
  final Duration defaultTimeout;

  String? _authToken;

  ApiClient({
    required this.baseUrl,
    http.Client? client,
    this.defaultTimeout = const Duration(seconds: 30),
  }) : client = client ?? http.Client();

  void setAuthToken(String token) {
    _authToken = token;
  }

  void clearAuthToken() {
    _authToken = null;
  }

  Map<String, String> _buildHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-App-Version': ApiConstants.appVersion,
    };

    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    return headers;
  }

  Future<dynamic> get(
      String endpoint, {
        Map<String, String>? queryParams,
        Duration? timeout,
      }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint')
          .replace(queryParameters: queryParams);

      if (kDebugMode) {
        print('GET Request: ${uri.toString()}');
      }

      final response = await client
          .get(uri, headers: _buildHeaders())
          .timeout(timeout ?? defaultTimeout);

      return _handleResponse(response);
    } on TimeoutException {
      throw NetworkException('Request timed out');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw NetworkException('Network error: ${e.toString()}');
    }
  }

  Future<dynamic> post(
      String endpoint, {
        dynamic body,
        Map<String, String>? queryParams,
        Duration? timeout,
      }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint')
          .replace(queryParameters: queryParams);

      if (kDebugMode) {
        print('POST Request: ${uri.toString()}');
        print('Body: ${jsonEncode(body)}');
      }

      final response = await client
          .post(
        uri,
        headers: _buildHeaders(),
        body: body != null ? jsonEncode(body) : null,
      )
          .timeout(timeout ?? defaultTimeout);

      return _handleResponse(response);
    } on TimeoutException {
      throw NetworkException('Request timed out');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw NetworkException('Network error: ${e.toString()}');
    }
  }

  Future<dynamic> put(
      String endpoint, {
        dynamic body,
        Map<String, String>? queryParams,
        Duration? timeout,
      }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint')
          .replace(queryParameters: queryParams);

      if (kDebugMode) {
        print('PUT Request: ${uri.toString()}');
        print('Body: ${jsonEncode(body)}');
      }

      final response = await client
          .put(
        uri,
        headers: _buildHeaders(),
        body: body != null ? jsonEncode(body) : null,
      )
          .timeout(timeout ?? defaultTimeout);

      return _handleResponse(response);
    } on TimeoutException {
      throw NetworkException('Request timed out');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw NetworkException('Network error: ${e.toString()}');
    }
  }

  Future<dynamic> delete(
      String endpoint, {
        Map<String, String>? queryParams,
        Duration? timeout,
      }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint')
          .replace(queryParameters: queryParams);

      if (kDebugMode) {
        print('DELETE Request: ${uri.toString()}');
      }

      final response = await client
          .delete(uri, headers: _buildHeaders())
          .timeout(timeout ?? defaultTimeout);

      return _handleResponse(response);
    } on TimeoutException {
      throw NetworkException('Request timed out');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw NetworkException('Network error: ${e.toString()}');
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (kDebugMode) {
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return null;
      }

      try {
        return json.decode(response.body);
      } catch (e) {
        // For binary responses or non-JSON responses
        if (response.statusCode == 200) {
          return response.bodyBytes;
        }
        throw ApiException('Failed to parse response: ${e.toString()}');
      }
    } else {
      _handleErrorResponse(response);
    }
  }

  void _handleErrorResponse(http.Response response) {
    // Try to parse error details from response
    try {
      final errorData = json.decode(response.body);

      // Handle authentication errors
      if (response.statusCode == 401) {
        throw AuthException(
          errorData['detail'] ?? 'Authentication failed',
          code: 'auth_failed',
          data: errorData,
        );
      }

      // Handle validation errors
      if (response.statusCode == 422 && errorData['errors'] is Map) {
        throw ValidationException(
          errorData['message'] ?? 'Validation failed',
          fieldErrors: Map<String, List<String>>.from(
            (errorData['errors'] as Map).map(
                  (key, value) => MapEntry(
                key,
                value is List
                    ? List<String>.from(value)
                    : [value.toString()],
              ),
            ),
          ),
          data: errorData,
        );
      }

      // Handle general API errors
      throw ApiException.fromResponse(errorData, response.statusCode);
    } catch (e) {
      if (e is ApiException || e is AuthException || e is ValidationException) {
        rethrow;
      }

      // If parsing fails, use status code information
      final message = _getStatusCodeMessage(response.statusCode);
      throw ApiException(message, statusCode: response.statusCode);
    }
  }

  String _getStatusCodeMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad request';
      case 401:
        return 'Unauthorized';
      case 403:
        return 'Forbidden';
      case 404:
        return 'Not found';
      case 405:
        return 'Method not allowed';
      case 408:
        return 'Request timeout';
      case 409:
        return 'Conflict';
      case 422:
        return 'Validation error';
      case 429:
        return 'Too many requests';
      case 500:
        return 'Internal server error';
      case 502:
        return 'Bad gateway';
      case 503:
        return 'Service unavailable';
      case 504:
        return 'Gateway timeout';
      default:
        return 'HTTP Error $statusCode';
    }
  }
}