// lib/core/config/app_config.dart
import 'package:flutter/foundation.dart';

enum Environment { development, staging, production }

class AppConfig {
  static Environment environment = Environment.development;

  // API settings
  static String get apiBaseUrl {
    switch (environment) {
      case Environment.development:
        return 'http://localhost:8000';
      case Environment.staging:
        return 'https://staging-api.defiot.com';
      case Environment.production:
        return 'https://api.defiot.com';
    }
  }

  // Feature flags
  static bool get enableLogs => environment != Environment.production;
  static bool get enableDevMenu => environment != Environment.production;

  // Timeout settings
  static Duration get defaultTimeout => const Duration(seconds: 30);
  static Duration get longTimeout => const Duration(seconds: 60);

  // Cache settings
  static Duration get cacheMaxAge => const Duration(hours: 24);

  // App settings
  static String get appName => 'DEFIoT';
  static String get appVersion => '1.0.0';
  static String get buildNumber => '1';

  // Initialize app config based on environment
  static void init(Environment env) {
    environment = env;
    if (kDebugMode) {
      print('Initializing AppConfig with environment: $environment');
      print('API Base URL: $apiBaseUrl');
    }
  }
}