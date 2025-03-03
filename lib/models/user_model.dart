// lib/models/user_model.dart
class User {
  final int id;
  final String email;
  final String fullName;
  final String? phoneNumber;
  final String? profilePicture;
  final List<String> roles;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final bool isActive;
  final bool isVerified;
  final Map<String, dynamic> preferences;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    this.profilePicture,
    this.roles = const ['user'],
    required this.createdAt,
    this.lastLogin,
    this.isActive = true,
    this.isVerified = false,
    this.preferences = const {},
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'],
      phoneNumber: json['phone_number'],
      profilePicture: json['profile_picture'],
      roles: List<String>.from(json['roles'] ?? ['user']),
      createdAt: DateTime.parse(json['created_at']),
      lastLogin: json['last_login'] != null ? DateTime.parse(json['last_login']) : null,
      isActive: json['is_active'] ?? true,
      isVerified: json['is_verified'] ?? false,
      preferences: json['preferences'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'profile_picture': profilePicture,
      'roles': roles,
      'created_at': createdAt.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
      'is_active': isActive,
      'is_verified': isVerified,
      'preferences': preferences,
    };
  }

  bool get isAdmin => roles.contains('admin');

  User copyWith({
    int? id,
    String? email,
    String? fullName,
    String? phoneNumber,
    String? profilePicture,
    List<String>? roles,
    DateTime? createdAt,
    DateTime? lastLogin,
    bool? isActive,
    bool? isVerified,
    Map<String, dynamic>? preferences,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profilePicture: profilePicture ?? this.profilePicture,
      roles: roles ?? this.roles,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      preferences: preferences ?? this.preferences,
    );
  }
}