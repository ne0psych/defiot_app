// lib/core/config/environment_config.dart
import 'app_config.dart';

class EnvironmentConfig {
  static const String development = 'http://localhost:8000';
  static const String staging = 'https://staging-api.defiot.com';
  static const String production = 'https://api.defiot.com';

  static String get baseUrl {
    switch (AppConfig.environment) {
      case Environment.development:
        return development;
      case Environment.staging:
        return staging;
      case Environment.production:
        return production;
    }
  }
}