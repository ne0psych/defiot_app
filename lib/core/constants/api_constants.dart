// lib/core/constants/api_constants.dart
class ApiConstants {
  static const String appVersion = '1.0.0';
  static const String apiVersion = 'v1';

  // Endpoints
  static const String authEndpoint = '/auth';
  static const String devicesEndpoint = '/devices';
  static const String scansEndpoint = '/scans';
  static const String reportsEndpoint = '/reports';
  static const String settingsEndpoint = '/settings';

  // Timeouts
  static const int defaultTimeoutSeconds = 30;
  static const int uploadTimeoutSeconds = 120;
  static const int scanTimeoutSeconds = 180;

  // Pagination
  static const int defaultPageSize = 20;
}