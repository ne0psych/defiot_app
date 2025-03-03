// lib/models/settings_model.dart
class NotificationSettings {
  final bool pushNotifications;
  final bool emailNotifications;
  final bool newDeviceAlerts;
  final bool securityAlerts;
  final bool marketingEmails;

  NotificationSettings({
    this.pushNotifications = true,
    this.emailNotifications = true,
    this.newDeviceAlerts = true,
    this.securityAlerts = true,
    this.marketingEmails = false,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      pushNotifications: json['push_notifications'] ?? true,
      emailNotifications: json['email_notifications'] ?? true,
      newDeviceAlerts: json['new_device_alerts'] ?? true,
      securityAlerts: json['security_alerts'] ?? true,
      marketingEmails: json['marketing_emails'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'push_notifications': pushNotifications,
      'email_notifications': emailNotifications,
      'new_device_alerts': newDeviceAlerts,
      'security_alerts': securityAlerts,
      'marketing_emails': marketingEmails,
    };
  }

  NotificationSettings copyWith({
    bool? pushNotifications,
    bool? emailNotifications,
    bool? newDeviceAlerts,
    bool? securityAlerts,
    bool? marketingEmails,
  }) {
    return NotificationSettings(
      pushNotifications: pushNotifications ?? this.pushNotifications,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      newDeviceAlerts: newDeviceAlerts ?? this.newDeviceAlerts,
      securityAlerts: securityAlerts ?? this.securityAlerts,
      marketingEmails: marketingEmails ?? this.marketingEmails,
    );
  }
}

class SecuritySettings {
  final bool twoFactorAuth;
  final bool loginAlerts;
  final String apiKeyExpiry;
  final bool biometricAuth;
  final bool passwordChangeRequired;

  SecuritySettings({
    this.twoFactorAuth = false,
    this.loginAlerts = true,
    this.apiKeyExpiry = '30days',
    this.biometricAuth = false,
    this.passwordChangeRequired = false,
  });

  factory SecuritySettings.fromJson(Map<String, dynamic> json) {
    return SecuritySettings(
      twoFactorAuth: json['two_factor_auth'] ?? false,
      loginAlerts: json['login_alerts'] ?? true,
      apiKeyExpiry: json['api_key_expiry'] ?? '30days',
      biometricAuth: json['biometric_auth'] ?? false,
      passwordChangeRequired: json['password_change_required'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'two_factor_auth': twoFactorAuth,
      'login_alerts': loginAlerts,
      'api_key_expiry': apiKeyExpiry,
      'biometric_auth': biometricAuth,
      'password_change_required': passwordChangeRequired,
    };
  }

  SecuritySettings copyWith({
    bool? twoFactorAuth,
    bool? loginAlerts,
    String? apiKeyExpiry,
    bool? biometricAuth,
    bool? passwordChangeRequired,
  }) {
    return SecuritySettings(
      twoFactorAuth: twoFactorAuth ?? this.twoFactorAuth,
      loginAlerts: loginAlerts ?? this.loginAlerts,
      apiKeyExpiry: apiKeyExpiry ?? this.apiKeyExpiry,
      biometricAuth: biometricAuth ?? this.biometricAuth,
      passwordChangeRequired: passwordChangeRequired ?? this.passwordChangeRequired,
    );
  }
}

class AppSettings {
  final String theme;
  final String language;
  final bool autoUpdate;
  final bool developerMode;
  final bool analyticsEnabled;
  final Map<String, dynamic> customConfigurations;

  AppSettings({
    this.theme = 'system',
    this.language = 'english',
    this.autoUpdate = true,
    this.developerMode = false,
    this.analyticsEnabled = true,
    this.customConfigurations = const {},
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      theme: json['theme'] ?? 'system',
      language: json['language'] ?? 'english',
      autoUpdate: json['auto_update'] ?? true,
      developerMode: json['developer_mode'] ?? false,
      analyticsEnabled: json['analytics_enabled'] ?? true,
      customConfigurations: json['custom_configurations'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'theme': theme,
      'language': language,
      'auto_update': autoUpdate,
      'developer_mode': developerMode,
      'analytics_enabled': analyticsEnabled,
      'custom_configurations': customConfigurations,
    };
  }

  AppSettings copyWith({
    String? theme,
    String? language,
    bool? autoUpdate,
    bool? developerMode,
    bool? analyticsEnabled,
    Map<String, dynamic>? customConfigurations,
  }) {
    return AppSettings(
      theme: theme ?? this.theme,
      language: language ?? this.language,
      autoUpdate: autoUpdate ?? this.autoUpdate,
      developerMode: developerMode ?? this.developerMode,
      analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
      customConfigurations: customConfigurations ?? this.customConfigurations,
    );
  }
}

class UserProfile {
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String? profilePicture;
  final DateTime? lastLogin;
  final String? organization;
  final List<String> roles;

  UserProfile({
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.profilePicture,
    this.lastLogin,
    this.organization,
    this.roles = const [],
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      fullName: json['full_name'],
      email: json['email'],
      phoneNumber: json['phone_number'],
      profilePicture: json['profile_picture'],
      lastLogin: json['last_login'] != null
          ? DateTime.parse(json['last_login'])
          : null,
      organization: json['organization'],
      roles: List<String>.from(json['roles'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'email': email,
      'phone_number': phoneNumber,
      'profile_picture': profilePicture,
      'last_login': lastLogin?.toIso8601String(),
      'organization': organization,
      'roles': roles,
    };
  }

  UserProfile copyWith({
    String? fullName,
    String? email,
    String? phoneNumber,
    String? profilePicture,
    DateTime? lastLogin,
    String? organization,
    List<String>? roles,
  }) {
    return UserProfile(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profilePicture: profilePicture ?? this.profilePicture,
      lastLogin: lastLogin ?? this.lastLogin,
      organization: organization ?? this.organization,
      roles: roles ?? this.roles,
    );
  }
}

class ApiKeySettings {
  final String key;
  final DateTime expiresAt;
  final DateTime createdAt;
  final String? description;
  final List<String> permissions;
  final bool isActive;

  ApiKeySettings({
    required this.key,
    required this.expiresAt,
    required this.createdAt,
    this.description,
    this.permissions = const [],
    this.isActive = true,
  });

  factory ApiKeySettings.fromJson(Map<String, dynamic> json) {
    return ApiKeySettings(
      key: json['key'],
      expiresAt: DateTime.parse(json['expires_at']),
      createdAt: DateTime.parse(json['created_at']),
      description: json['description'],
      permissions: List<String>.from(json['permissions'] ?? []),
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'expires_at': expiresAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'description': description,
      'permissions': permissions,
      'is_active': isActive,
    };
  }

  ApiKeySettings copyWith({
    String? key,
    DateTime? expiresAt,
    DateTime? createdAt,
    String? description,
    List<String>? permissions,
    bool? isActive,
  }) {
    return ApiKeySettings(
      key: key ?? this.key,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
      permissions: permissions ?? this.permissions,
      isActive: isActive ?? this.isActive,
    );
  }
}