/// Constants used throughout the application
class AppConstants {
  // App Information
  static const String appName = 'DEFIoT';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'IoT Security Simplified';

  // API Endpoints
  static const String apiBaseUrl = 'http://127.0.0.1:8000';

  // Authentication
  static const int tokenExpiryDays = 30;
  static const int minPasswordLength = 8;

  // Session Timeout
  static const int sessionTimeoutMinutes = 30;

  // Image Upload
  static const int maxImageSizeKB = 1024;
  static const int imageQuality = 85;
  static const int maxProfilePicWidth = 800;
  static const int maxProfilePicHeight = 800;

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Cache
  static const int cacheExpiryDays = 7;

  // Scanning
  static const int scanTimeoutSeconds = 120;
  static const int minScanInterval = 6; // hours
  static const double defaultScanProgress = 0.0;

  // Animation Durations
  static const int shortAnimationDuration = 200; // milliseconds
  static const int mediumAnimationDuration = 500; // milliseconds
  static const int longAnimationDuration = 800; // milliseconds

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 12.0;
  static const double defaultButtonHeight = 56.0;
  static const double smallIconSize = 16.0;
  static const double mediumIconSize = 24.0;
  static const double largeIconSize = 36.0;

  // Theme
  static const String defaultTheme = 'system';

  // Language Options
  static const List<LanguageOption> languageOptions = [
    LanguageOption(value: 'english', label: 'English'),
    LanguageOption(value: 'spanish', label: 'Spanish'),
    LanguageOption(value: 'french', label: 'French'),
    LanguageOption(value: 'german', label: 'German'),
    LanguageOption(value: 'chinese', label: 'Chinese'),
    LanguageOption(value: 'japanese', label: 'Japanese'),
    LanguageOption(value: 'arabic', label: 'Arabic'),
  ];

  // Device Types
  static const List<DeviceTypeOption> deviceTypes = [
    DeviceTypeOption(value: 'smart_camera', label: 'Smart Camera'),
    DeviceTypeOption(value: 'smart_lock', label: 'Smart Lock'),
    DeviceTypeOption(value: 'thermostat', label: 'Thermostat'),
    DeviceTypeOption(value: 'smart_light', label: 'Smart Light'),
    DeviceTypeOption(value: 'smart_speaker', label: 'Smart Speaker'),
    DeviceTypeOption(value: 'router', label: 'Router/Gateway'),
    DeviceTypeOption(value: 'security_system', label: 'Security System'),
    DeviceTypeOption(value: 'smart_tv', label: 'Smart TV'),
    DeviceTypeOption(value: 'other', label: 'Other'),
  ];

  // Vulnerability Types
  static const List<VulnerabilityType> vulnerabilityTypes = [
    VulnerabilityType(
      value: 'WEAK_CREDENTIALS',
      label: 'Weak Credentials',
      icon: 'password',
      description: 'Weak or default passwords that are easily guessed',
      severity: 'high',
    ),
    VulnerabilityType(
      value: 'INSECURE_PROTOCOLS',
      label: 'Insecure Protocols',
      icon: 'security',
      description: 'Use of unencrypted communication protocols',
      severity: 'high',
    ),
    VulnerabilityType(
      value: 'OPEN_PORTS',
      label: 'Open Ports',
      icon: 'router',
      description: 'Unnecessary open ports increasing attack surface',
      severity: 'medium',
    ),
    VulnerabilityType(
      value: 'AUTH_BYPASS',
      label: 'Authentication Bypass',
      icon: 'no_encryption',
      description: 'Vulnerabilities allowing authentication to be bypassed',
      severity: 'critical',
    ),
    VulnerabilityType(
      value: 'FIRMWARE_ISSUES',
      label: 'Firmware Issues',
      icon: 'system_update',
      description: 'Outdated firmware with known vulnerabilities',
      severity: 'high',
    ),
    VulnerabilityType(
      value: 'ENCRYPTION_ISSUES',
      label: 'Encryption Issues',
      icon: 'lock_open',
      description: 'Weak or missing encryption for sensitive data',
      severity: 'high',
    ),
    VulnerabilityType(
      value: 'DEFAULT_CREDENTIALS',
      label: 'Default Credentials',
      icon: 'key_off',
      description: 'Factory default credentials that haven\'t been changed',
      severity: 'critical',
    ),
  ];

  // Risk Levels
  static const Map<String, RiskLevelInfo> riskLevels = {
    'critical': RiskLevelInfo(
      color: 0xFF9D0208,
      backgroundColor: 0xFFFCDDE0,
      label: 'Critical',
      icon: 'dangerous',
    ),
    'high': RiskLevelInfo(
      color: 0xFFDC2F02,
      backgroundColor: 0xFFFFE8D6,
      label: 'High',
      icon: 'error',
    ),
    'medium': RiskLevelInfo(
      color: 0xFFE85D04,
      backgroundColor: 0xFFFAE1DD,
      label: 'Medium',
      icon: 'warning',
    ),
    'low': RiskLevelInfo(
      color: 0xFF2B9348,
      backgroundColor: 0xFFD8F3DC,
      label: 'Low',
      icon: 'check_circle',
    ),
  };

  // Scan Types
  static const Map<String, ScanTypeInfo> scanTypes = {
    'quick': ScanTypeInfo(
      label: 'Quick Scan',
      description: 'Basic scan of essential security features',
      icon: 'speed',
      duration: 'Approx. 1-2 minutes',
    ),
    'full': ScanTypeInfo(
      label: 'Full Scan',
      description: 'Complete security assessment of the device',
      icon: 'security',
      duration: 'Approx. 3-5 minutes',
    ),
    'custom': ScanTypeInfo(
      label: 'Custom Scan',
      description: 'Specify which security aspects to scan',
      icon: 'tune',
      duration: 'Varies based on selection',
    ),
  };

  // Report Filter Options
  static const Map<String, String> reportFilterOptions = {
    'day': 'Daily',
    'week': 'Weekly',
    'month': 'Monthly',
    'custom': 'Custom Range',
  };
  static const Map<String, dynamic> defaultSettings = {
    'theme': 'system',
    'language': 'english',
    'autoUpdate': true,
    'analyticsEnabled': true,
    'developerMode': false,
    'notificationsEnabled': true,
  };
  // Report Export Formats
  static const Map<String, String> reportExportFormats = {
    'pdf': 'PDF Document',
    'csv': 'CSV Spreadsheet',
    'json': 'JSON Data',
    'html': 'HTML Document',
  };

  // Error Messages
  static const String networkErrorMessage = 'Network error. Please check your connection and try again.';
  static const String serverErrorMessage = 'Server error. Please try again later.';
  static const String unauthorizedErrorMessage = 'Unauthorized. Please login again.';
  static const String timeoutErrorMessage = 'Request timed out. Please try again.';
  static const String unknownErrorMessage = 'An unknown error occurred. Please try again.';

  // Success Messages
  static const String scanCompletedMessage = 'Scan completed successfully.';
  static const String deviceAddedMessage = 'Device added successfully.';
  static const String deviceUpdatedMessage = 'Device updated successfully.';
  static const String deviceDeletedMessage = 'Device deleted successfully.';
  static const String reportGeneratedMessage = 'Report generated successfully.';
  static const String settingsUpdatedMessage = 'Settings updated successfully.';
  static const String passwordChangedMessage = 'Password changed successfully.';
  static const String profileUpdatedMessage = 'Profile updated successfully.';
  static const String routeLogin = '/login';
  static const String routeAddDevice = '/devices/add';
  static const String routeApiKeys = '/settings/api-keys';
  static const String routeSubscription = '/settings/subscription';
  static const String routeHelp = '/settings/help';
  static const String routeTerms = '/settings/terms';
  static const String routeReportProblem = '/settings/report-problem';
}

  // Default Values
  const Map<String, dynamic> defaultSettings = {
    'theme': 'system',
    'language': 'english',
    'autoUpdate': true,
    'analyticsEnabled': true,
    'developerMode': false,
    'notificationsEnabled': true,
  };


/// Language option model for dropdowns
class LanguageOption {
  final String value;
  final String label;

  const LanguageOption({
    required this.value,
    required this.label,
  });
}

/// Device type option model for dropdowns
class DeviceTypeOption {
  final String value;
  final String label;

  const DeviceTypeOption({
    required this.value,
    required this.label,
  });
}

/// Vulnerability type model
class VulnerabilityType {
  final String value;
  final String label;
  final String icon;
  final String description;
  final String severity;

  const VulnerabilityType({
    required this.value,
    required this.label,
    required this.icon,
    required this.description,
    required this.severity,
  });
}

/// Risk level information model
class RiskLevelInfo {
  final int color;
  final int backgroundColor;
  final String label;
  final String icon;

  const RiskLevelInfo({
    required this.color,
    required this.backgroundColor,
    required this.label,
    required this.icon,
  });
}

/// Scan type information model
class ScanTypeInfo {
  final String label;
  final String description;
  final String icon;
  final String duration;

  const ScanTypeInfo({
    required this.label,
    required this.description,
    required this.icon,
    required this.duration,
  });
}