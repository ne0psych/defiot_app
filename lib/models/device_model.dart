// lib/models/device_model.dart
import 'package:flutter/foundation.dart';

enum DeviceStatus {
  active,
  inactive,
  unknown
}

enum RiskLevel {
  low,
  medium,
  high,
  critical
}

class Device {
  final int id;
  final String deviceName;
  final String? deviceType;
  final String macAddress;
  final String ipAddress;
  final DeviceStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Security-related fields
  final String? firmwareVersion;
  final DateTime? lastScanDate;
  final RiskLevel riskLevel;
  final double securityScore;
  final int openVulnerabilities;
  final int criticalIssues;
  final int highIssues;
  final int mediumIssues;
  final int lowIssues;
  final Map<String, dynamic> securityDetails;
  bool isSelected;

  Device({
    required this.id,
    required this.deviceName,
    this.deviceType,
    required this.ipAddress,
    required this.macAddress,
    this.status = DeviceStatus.unknown,
    required this.createdAt,
    this.updatedAt,
    this.firmwareVersion,
    this.lastScanDate,
    this.riskLevel = RiskLevel.low,
    this.securityScore = 0.0,
    this.openVulnerabilities = 0,
    this.criticalIssues = 0,
    this.highIssues = 0,
    this.mediumIssues = 0,
    this.lowIssues = 0,
    this.securityDetails = const {},
    this.isSelected = false,
  });

  int get deviceId => id;
  bool get isOnline => status == DeviceStatus.active;

  factory Device.fromJson(Map<String, dynamic> json) {
    if (kDebugMode) {
      print('Received JSON for device: $json');
    }

    final deviceId = json['id'] ?? json['deviceId'] ?? json['device_id'];
    if (deviceId == null) {
      throw Exception('Device must have either deviceId or id. Received keys: ${json.keys.toList()}');
    }

    return Device(
      id: deviceId is String ? int.parse(deviceId) : deviceId as int,
      deviceName: json['device_name'] ?? '',
      deviceType: json['device_type'],
      ipAddress: json['ip_address'] ?? '',
      macAddress: json['mac_address'] ?? '',
      status: _parseStatus(json['status']),
      createdAt: _parseDateTime(json['created_at']) ?? DateTime.now(),
      updatedAt: _parseDateTime(json['updated_at']),
      firmwareVersion: json['firmware_version'],
      lastScanDate: _parseDateTime(json['last_scan_date']),
      riskLevel: _parseRiskLevel(json['risk_level']),
      securityScore: (json['security_score'] ?? 0.0).toDouble(),
      openVulnerabilities: json['open_vulnerabilities'] ?? 0,
      criticalIssues: json['critical_issues'] ?? 0,
      highIssues: json['high_issues'] ?? 0,
      mediumIssues: json['medium_issues'] ?? 0,
      lowIssues: json['low_issues'] ?? 0,
      securityDetails: json['security_details'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'device_id': id,
      'device_name': deviceName,
      'device_type': deviceType,
      'ip_address': ipAddress,
      'mac_address': macAddress,
      'status': status.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'firmware_version': firmwareVersion,
      'last_scan_date': lastScanDate?.toIso8601String(),
      'risk_level': riskLevel.toString().split('.').last,
      'security_score': securityScore,
      'open_vulnerabilities': openVulnerabilities,
      'critical_issues': criticalIssues,
      'high_issues': highIssues,
      'medium_issues': mediumIssues,
      'low_issues': lowIssues,
      'security_details': securityDetails,
    };
  }

  static DateTime? _parseDateTime(dynamic dateStr) {
    if (dateStr == null) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing date: $e');
      }
      return null;
    }
  }

  static DeviceStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return DeviceStatus.active;
      case 'inactive':
        return DeviceStatus.inactive;
      default:
        return DeviceStatus.unknown;
    }
  }

  static RiskLevel _parseRiskLevel(String? level) {
    switch (level?.toLowerCase()) {
      case 'critical':
        return RiskLevel.critical;
      case 'high':
        return RiskLevel.high;
      case 'medium':
        return RiskLevel.medium;
      case 'low':
      default:
        return RiskLevel.low;
    }
  }

  Device copyWith({
    int? id,
    String? deviceName,
    String? deviceType,
    String? ipAddress,
    String? macAddress,
    DeviceStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? firmwareVersion,
    DateTime? lastScanDate,
    RiskLevel? riskLevel,
    double? securityScore,
    int? openVulnerabilities,
    int? criticalIssues,
    int? highIssues,
    int? mediumIssues,
    int? lowIssues,
    Map<String, dynamic>? securityDetails,
    bool? isSelected,
  }) {
    return Device(
      id: id ?? this.id,
      deviceName: deviceName ?? this.deviceName,
      deviceType: deviceType ?? this.deviceType,
      ipAddress: ipAddress ?? this.ipAddress,
      macAddress: macAddress ?? this.macAddress,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      lastScanDate: lastScanDate ?? this.lastScanDate,
      riskLevel: riskLevel ?? this.riskLevel,
      securityScore: securityScore ?? this.securityScore,
      openVulnerabilities: openVulnerabilities ?? this.openVulnerabilities,
      criticalIssues: criticalIssues ?? this.criticalIssues,
      highIssues: highIssues ?? this.highIssues,
      mediumIssues: mediumIssues ?? this.mediumIssues,
      lowIssues: lowIssues ?? this.lowIssues,
      securityDetails: securityDetails ?? this.securityDetails,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}