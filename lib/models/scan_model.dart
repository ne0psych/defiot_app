// lib/models/scan_model.dart
import 'package:flutter/foundation.dart';
import 'device_model.dart';
import 'vulnerability_model.dart';

enum ScanStatus { pending, inProgress, completed, failed }
enum ScanType { quick, full, custom }

class ServiceInfo {
  final String name;
  final String? version;
  final String protocol;
  final bool isSecure;
  final List<String> knownVulnerabilities;

  ServiceInfo({
    required this.name,
    this.version,
    required this.protocol,
    required this.isSecure,
    this.knownVulnerabilities = const [],
  });

  factory ServiceInfo.fromJson(Map<String, dynamic> json) {
    return ServiceInfo(
      name: json['name'] ?? '',
      version: json['version'],
      protocol: json['protocol'] ?? 'tcp',
      isSecure: json['is_secure'] ?? false,
      knownVulnerabilities: List<String>.from(json['known_vulnerabilities'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'version': version,
      'protocol': protocol,
      'is_secure': isSecure,
      'known_vulnerabilities': knownVulnerabilities,
    };
  }
}

class PortInfo {
  final int portNumber;
  final String protocol;
  final ServiceInfo? service;
  final String state;
  final DateTime? lastSeen;

  PortInfo({
    required this.portNumber,
    required this.protocol,
    this.service,
    required this.state,
    this.lastSeen,
  });

  factory PortInfo.fromJson(Map<String, dynamic> json) {
    return PortInfo(
      portNumber: json['port_number'] as int,
      protocol: json['protocol'] as String,
      service: json['service'] != null ? ServiceInfo.fromJson(json['service']) : null,
      state: json['state'] as String,
      lastSeen: json['last_seen'] != null ? DateTime.parse(json['last_seen']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'port_number': portNumber,
      'protocol': protocol,
      'service': service?.toJson(),
      'state': state,
      'last_seen': lastSeen?.toIso8601String(),
    };
  }
}

class Scan {
  final int scanId;
  final int deviceId;
  final int userId;
  final ScanStatus status;
  final RiskLevel riskLevel;
  final String scanType;
  final double? securityScore;
  final int vulnerabilitiesFound;
  final double? scanDuration;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final Map<String, dynamic> scanConfiguration;
  final ScanResult? result;

  Scan({
    required this.scanId,
    required this.deviceId,
    required this.userId,
    required this.status,
    required this.riskLevel,
    required this.scanType,
    this.securityScore,
    required this.vulnerabilitiesFound,
    this.scanDuration,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    required this.scanConfiguration,
    this.result,
  });

  factory Scan.fromJson(Map<String, dynamic> json) {
    return Scan(
      scanId: json['scan_id'] as int,
      deviceId: json['device_id'] as int,
      userId: json['user_id'] as int,
      status: ScanStatus.values.firstWhere(
            (e) => e.toString().split('.').last == json['status'],
        orElse: () => ScanStatus.pending,
      ),
      riskLevel: RiskLevel.values.firstWhere(
            (e) => e.toString().split('.').last == json['risk_level'],
        orElse: () => RiskLevel.low,
      ),
      scanType: json['scan_type'] ?? 'full',
      securityScore: json['security_score']?.toDouble(),
      vulnerabilitiesFound: json['vulnerabilities_found'] ?? 0,
      scanDuration: json['scan_duration']?.toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      startedAt: json['started_at'] != null ? DateTime.parse(json['started_at']) : null,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      scanConfiguration: json['scan_configuration'] ?? {},
      result: json['result'] != null ? ScanResult.fromJson(json['result']) : null,
    );
  }

  Scan copyWith({
    int? scanId,
    int? deviceId,
    int? userId,
    ScanStatus? status,
    RiskLevel? riskLevel,
    String? scanType,
    double? securityScore,
    int? vulnerabilitiesFound,
    double? scanDuration,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    Map<String, dynamic>? scanConfiguration,
    ScanResult? result,
  }) {
    return Scan(
      scanId: scanId ?? this.scanId,
      deviceId: deviceId ?? this.deviceId,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      riskLevel: riskLevel ?? this.riskLevel,
      scanType: scanType ?? this.scanType,
      securityScore: securityScore ?? this.securityScore,
      vulnerabilitiesFound: vulnerabilitiesFound ?? this.vulnerabilitiesFound,
      scanDuration: scanDuration ?? this.scanDuration,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      scanConfiguration: scanConfiguration ?? this.scanConfiguration,
      result: result ?? this.result,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'scan_id': scanId,
      'device_id': deviceId,
      'user_id': userId,
      'status': status.toString().split('.').last,
      'risk_level': riskLevel.toString().split('.').last,
      'scan_type': scanType,
      'security_score': securityScore,
      'vulnerabilities_found': vulnerabilitiesFound,
      'scan_duration': scanDuration,
      'created_at': createdAt.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'scan_configuration': scanConfiguration,
      'result': result?.toJson(),
    };
  }
}

class ScanResult {
  final DateTime timestamp;
  final String host;
  final String status;
  final List<PortInfo> openPorts;
  final RiskLevel riskLevel;
  final int vulnerabilitiesFound;
  final List<Vulnerability> vulnerabilities;
  final double? securityScore;
  final double? scanDuration;
  final Map<String, dynamic> rawData;

  ScanResult({
    required this.timestamp,
    required this.host,
    required this.status,
    required this.openPorts,
    required this.riskLevel,
    required this.vulnerabilitiesFound,
    required this.vulnerabilities,
    this.securityScore,
    this.scanDuration,
    required this.rawData,
  });

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    // Parse open ports
    final openPorts = <PortInfo>[];
    if (json['open_ports'] != null) {
      (json['open_ports'] as List).forEach((port) {
        openPorts.add(PortInfo.fromJson(port as Map<String, dynamic>));
      });
    }

    // Parse vulnerabilities
    final vulnerabilities = <Vulnerability>[];
    if (json['vulnerabilities'] != null) {
      (json['vulnerabilities'] as List).forEach((vuln) {
        vulnerabilities.add(Vulnerability.fromJson(vuln as Map<String, dynamic>));
      });
    }

    return ScanResult(
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      host: json['host'] ?? '',
      status: json['status'] ?? 'completed',
      openPorts: openPorts,
      riskLevel: _parseRiskLevel(json['risk_level']),
      vulnerabilitiesFound: json['vulnerabilities_found'] ?? 0,
      vulnerabilities: vulnerabilities,
      securityScore: json['security_score']?.toDouble(),
      scanDuration: json['scan_duration']?.toDouble(),
      rawData: json['raw_data'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'host': host,
      'status': status,
      'open_ports': openPorts.map((port) => port.toJson()).toList(),
      'risk_level': riskLevel.toString().split('.').last,
      'vulnerabilities_found': vulnerabilitiesFound,
      'vulnerabilities': vulnerabilities.map((v) => v.toJson()).toList(),
      'security_score': securityScore,
      'scan_duration': scanDuration,
      'raw_data': rawData,
    };
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
}

// Utility class for scan configuration
class ScanConfiguration {
  final ScanType scanType;
  final Map<String, dynamic> customOptions;

  ScanConfiguration({
    this.scanType = ScanType.full,
    this.customOptions = const {},
  });

  factory ScanConfiguration.fromJson(Map<String, dynamic> json) {
    return ScanConfiguration(
      scanType: _parseScanType(json['scan_type']),
      customOptions: json['custom_options'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'scan_type': scanType.toString().split('.').last,
      'custom_options': customOptions,
    };
  }

  static ScanType _parseScanType(String? type) {
    switch (type?.toLowerCase()) {
      case 'quick':
        return ScanType.quick;
      case 'custom':
        return ScanType.custom;
      case 'full':
      default:
        return ScanType.full;
    }
  }
}