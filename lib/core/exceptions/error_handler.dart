import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import 'app_exceptions.dart';

/// A utility class for handling errors throughout the application
class ErrorHandler {
  /// Transforms various errors into user-friendly AppExceptions
  static AppException handleError(dynamic error) {
    if (error is AppException) {
      return error;
    }

    // Handle common error types
    if (error is SocketException) {
      return NetworkException(message: AppConstants.networkErrorMessage);
    }

    if (error is TimeoutException) {
      return TimeoutException(message: AppConstants.timeoutErrorMessage);
    }

    if (error is FormatException) {
      return DataFormatException(message: 'Data format error: ${error.message}');
    }

    if (error is http.ClientException) {
      return NetworkException(message: 'HTTP client error: ${error.message}');
    }

    // Default to unknown error
    return UnknownException(
      message: AppConstants.unknownErrorMessage,
      exception: error,
    );
  }

  /// Handles network response errors based on status codes
  static AppException handleHttpResponse(http.Response response) {
    switch (response.statusCode) {
      case 400:
        return BadRequestException(
          message: _parseErrorMessage(response) ?? 'Bad request',
          statusCode: response.statusCode,
        );
      case 401:
        return UnauthorizedException(
          message: AppConstants.unauthorizedErrorMessage,
          statusCode: response.statusCode,
        );
      case 403:
        return ForbiddenException(
          message: 'Access forbidden',
          statusCode: response.statusCode,
        );
      case 404:
        return NotFoundException(
          message: 'Resource not found',
          statusCode: response.statusCode,
        );
      case 409:
        return ConflictException(
          message: _parseErrorMessage(response) ?? 'Conflict occurred',
          statusCode: response.statusCode,
        );
      case 422:
        return ValidationException(
          message: _parseErrorMessage(response) ?? 'Validation failed',
          statusCode: response.statusCode,
          errors: _parseValidationErrors(response),
        );
      case 429:
        return RateLimitedException(
          message: 'Too many requests. Please try again later',
          statusCode: response.statusCode,
        );
      default:
        if (response.statusCode >= 500) {
          return ServerException(
            message: AppConstants.serverErrorMessage,
            statusCode: response.statusCode,
          );
        }
        return HttpException(
          message: _parseErrorMessage(response) ?? 'HTTP error ${response.statusCode}',
          statusCode: response.statusCode,
        );
    }
  }

  /// Parses error message from HTTP response
  static String? _parseErrorMessage(http.Response response) {
    try {
      final Map<String, dynamic> data = json.decode(response.body);

      // Handle different error formats
      if (data.containsKey('detail')) {
        return data['detail'];
      } else if (data.containsKey('message')) {
        return data['message'];
      } else if (data.containsKey('error')) {
        if (data['error'] is String) {
          return data['error'];
        } else if (data['error'] is Map && data['error'].containsKey('message')) {
          return data['error']['message'];
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Parses validation errors from HTTP response
  static Map<String, String>? _parseValidationErrors(http.Response response) {
    try {
      final Map<String, dynamic> data = json.decode(response.body);

      // Handle different validation error formats
      if (data.containsKey('errors') && data['errors'] is Map) {
        final Map<String, dynamic> errors = data['errors'];
        final Map<String, String> formattedErrors = {};

        errors.forEach((key, value) {
          if (value is List) {
            formattedErrors[key] = value.join(', ');
          } else if (value is String) {
            formattedErrors[key] = value;
          }
        });

        return formattedErrors;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Displays an error snackbar
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(8),
      ),
    );
  }

  /// Displays a success snackbar
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(8),
      ),
    );
  }

  /// Gets a user-friendly error message based on the exception type
  static String getErrorMessage(dynamic error) {
    final AppException appException = handleError(error);
    return appException.message;
  }

  /// Logs error to console or remote service
  static void logError(dynamic error, [StackTrace? stackTrace]) {
    // In a production app, you might want to send this to a logging service
    debugPrint('ERROR: ${error.toString()}');
    if (stackTrace != null) {
      debugPrint('STACKTRACE: ${stackTrace.toString()}');
    }
  }
}