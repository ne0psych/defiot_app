// lib/models/report_model.dart
import 'package:intl/intl.dart';
import 'device_model.dart';

enum ReportType {
  daily,
  weekly,
  monthly,
  custom
}

class Report {
  final int reportId;
  final int userId;
  final String reportType;
  final DateTime startDate;
  final DateTime endDate;
  final int totalScans;
  final int successRate;
  final int issuesCount;
  final ReportSummary summaryData;
  final DateTime createdAt;

  Report({
    required this.reportId,
    required this.userId,
    required this.reportType,
    required this.startDate,
    required this.endDate,
    required this.totalScans,
    required this.successRate,
    required this.issuesCount,
    required this.summaryData,
    required this.createdAt,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    try {
      return Report(
        reportId: json['report_id'],
        userId: json['user_id'] ?? 0,
        reportType: json['report_type'],
        startDate: DateTime.parse(json['start_date']),
        endDate: DateTime.parse(json['end_date']),
        totalScans: json['total_scans'],
        successRate: json['success_rate'],
        issuesCount: json['issues_count'],
        summaryData: ReportSummary.fromJson(json['summary_data'] ?? {}),
        createdAt: DateTime.parse(json['created_at']),
      );
    } catch (e) {
      print('Error parsing Report JSON: $e');
      print('Problematic JSON: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'report_id': reportId,
      'user_id': userId,
      'report_type': reportType,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'total_scans': totalScans,
      'success_rate': successRate,
      'issues_count': issuesCount,
      'summary_data': summaryData.toJson(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  String getFormattedName() {
    final dateStr = DateFormat('yyyy-MM-dd').format(startDate);
    return 'Security_Report_${reportId}_$dateStr';
  }
}

class ReportSummary {
  final Map<String, int> dailyCounts;
  final Map<String, int> riskLevels;
  final List<DeviceVulnerability> topVulnerabilities;
  final double? securityScore;
  final Map<String, dynamic> additionalMetrics;

  ReportSummary({
    required this.dailyCounts,
    required this.riskLevels,
    this.topVulnerabilities = const [],
    this.securityScore,
    this.additionalMetrics = const {},
  });

  factory ReportSummary.fromJson(Map<String, dynamic> json) {
    // Parse daily counts
    final dailyCounts = <String, int>{};
    if (json['daily_counts'] != null) {
      (json['daily_counts'] as Map<String, dynamic>).forEach((key, value) {
        dailyCounts[key] = value as int;
      });
    }

    // Parse risk levels
    final riskLevels = <String, int>{};
    if (json['risk_levels'] != null) {
      (json['risk_levels'] as Map<String, dynamic>).forEach((key, value) {
        riskLevels[key] = value as int;
      });
    }

    // Parse top vulnerabilities
    final topVulnerabilities = <DeviceVulnerability>[];
    if (json['top_vulnerabilities'] != null) {
      (json['top_vulnerabilities'] as List).forEach((vuln) {
        topVulnerabilities.add(DeviceVulnerability.fromJson(vuln));
      });
    }

    return ReportSummary(
      dailyCounts: dailyCounts,
      riskLevels: riskLevels,
      topVulnerabilities: topVulnerabilities,
      securityScore: json['security_score']?.toDouble(),
      additionalMetrics: json['additional_metrics'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'daily_counts': dailyCounts,
      'risk_levels': riskLevels,
      'top_vulnerabilities': topVulnerabilities.map((v) => v.toJson()).toList(),
      'security_score': securityScore,
      'additional_metrics': additionalMetrics,
    };
  }
}

class DeviceVulnerability {
  final String deviceId;
  final String deviceName;
  final String vulnerabilityType;
  final RiskLevel severity;
  final int count;

  DeviceVulnerability({
    required this.deviceId,
    required this.deviceName,
    required this.vulnerabilityType,
    required this.severity,
    required this.count,
  });

  factory DeviceVulnerability.fromJson(Map<String, dynamic> json) {
    return DeviceVulnerability(
      deviceId: json['device_id'].toString(),
      deviceName: json['device_name'] ?? '',
      vulnerabilityType: json['vulnerability_type'] ?? '',
      severity: _parseRiskLevel(json['severity']),
      count: json['count'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
      'device_name': deviceName,
      'vulnerability_type': vulnerabilityType,
      'severity': severity.toString().split('.').last,
      'count': count,
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