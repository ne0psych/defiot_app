/// Base exception class for the application
class AppException implements Exception {
  final String message;
  final dynamic exception;

  AppException({
    required this.message,
    this.exception,
  });

  @override
  String toString() => message;
}

/// Exception for network connectivity issues
class NetworkException extends AppException {
  NetworkException({
    required String message,
    dynamic exception,
  }) : super(message: message, exception: exception);
}

/// Exception for server errors (5xx status codes)
class ServerException extends AppException {
  final int? statusCode;

  ServerException({
    required String message,
    this.statusCode,
    dynamic exception,
  }) : super(message: message, exception: exception);
}

/// Exception for timeout errors
class TimeoutException extends AppException {
  TimeoutException({
    required String message,
    dynamic exception,
  }) : super(message: message, exception: exception);
}

/// Exception for data format errors
class DataFormatException extends AppException {
  DataFormatException({
    required String message,
    dynamic exception,
  }) : super(message: message, exception: exception);
}

/// Base exception class for HTTP request errors
class HttpException extends AppException {
  final int statusCode;

  HttpException({
    required String message,
    required this.statusCode,
    dynamic exception,
  }) : super(message: message, exception: exception);
}

/// Exception for 400 Bad Request
class BadRequestException extends HttpException {
  BadRequestException({
    required String message,
    required int statusCode,
    dynamic exception,
  }) : super(message: message, statusCode: statusCode, exception: exception);
}

/// Exception for 401 Unauthorized
class UnauthorizedException extends HttpException {
  UnauthorizedException({
    required String message,
    required int statusCode,
    dynamic exception,
  }) : super(message: message, statusCode: statusCode, exception: exception);
}

/// Exception for 403 Forbidden
class ForbiddenException extends HttpException {
  ForbiddenException({
    required String message,
    required int statusCode,
    dynamic exception,
  }) : super(message: message, statusCode: statusCode, exception: exception);
}

/// Exception for 404 Not Found
class NotFoundException extends HttpException {
  NotFoundException({
    required String message,
    required int statusCode,
    dynamic exception,
  }) : super(message: message, statusCode: statusCode, exception: exception);
}

/// Exception for 409 Conflict
class ConflictException extends HttpException {
  ConflictException({
    required String message,
    required int statusCode,
    dynamic exception,
  }) : super(message: message, statusCode: statusCode, exception: exception);
}

/// Exception for 422 Validation Error
class ValidationException extends HttpException {
  final Map<String, String>? errors;

  ValidationException({
    required String message,
    required int statusCode,
    this.errors,
    dynamic exception,
  }) : super(message: message, statusCode: statusCode, exception: exception);
}

/// Exception for 429 Rate Limited
class RateLimitedException extends HttpException {
  RateLimitedException({
    required String message,
    required int statusCode,
    dynamic exception,
  }) : super(message: message, statusCode: statusCode, exception: exception);
}

/// Exception for authentication errors
class AuthException extends AppException {
  AuthException({
    required String message,
    dynamic exception,
  }) : super(message: message, exception: exception);
}

/// Exception for cache errors
class CacheException extends AppException {
  CacheException({
    required String message,
    dynamic exception,
  }) : super(message: message, exception: exception);
}

/// Exception for device errors
class DeviceException extends AppException {
  DeviceException({
    required String message,
    dynamic exception,
  }) : super(message: message, exception: exception);
}

/// Exception for scan errors
class ScanException extends AppException {
  ScanException({
    required String message,
    dynamic exception,
  }) : super(message: message, exception: exception);
}

/// Exception for report errors
class ReportException extends AppException {
  ReportException({
    required String message,
    dynamic exception,
  }) : super(message: message, exception: exception);
}

/// Exception for vulnerability errors
class VulnerabilityException extends AppException {
  VulnerabilityException({
    required String message,
    dynamic exception,
  }) : super(message: message, exception: exception);
}

/// Exception for unexpected errors
class UnknownException extends AppException {
  UnknownException({
    required String message,
    dynamic exception,
  }) : super(message: message, exception: exception);
}