import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:html' as html;
import '../local/shared_prefs.dart';
import '../../core/exceptions/app_exceptions.dart';
import '../../core/exceptions/error_handler.dart';
import '../../models/report_model.dart';
import '../../services/report_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/date_formatter.dart';

/// Repository class that handles report operations
class ReportRepository {
  final http.Client _client;
  final String _baseUrl;

  ReportRepository({
    http.Client? client,
    String? baseUrl,
  }) :
        _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConstants.apiBaseUrl;

  /// Helper method to get the auth headers
  Future<Map<String, String>> _getHeaders() async {
    final token = SharedPrefs.getAuthToken();
    if (token == null) {
      throw AuthException(message: 'Not authenticated');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Get reports with optional filtering
  Future<List<Report>> getReports({
    required ReportType reportType,
    DateTime? startDate,
    DateTime? endDate,
    int skip = 0,
    int limit = 7,
  }) async {
    try {
      final queryParams = {
        'report_type': reportType.toString().split('.').last,
        'skip': skip.toString(),
        'limit': limit.toString(),
        if (startDate != null) 'start_date': startDate.toIso8601String(),
        if (endDate != null) 'end_date': endDate.toIso8601String(),
      };

      final uri = Uri.parse('$_baseUrl/reports').replace(queryParameters: queryParams);

      final response = await _client.get(
        uri,
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw ErrorHandler.handleHttpResponse(response);
      }

      final List<dynamic> reportsJson = jsonDecode(response.body);
      return reportsJson.map((json) => Report.fromJson(json)).toList();
    } catch (e) {
      if (e is http.ClientException) {
        throw NetworkException(message: 'Failed to load reports. Please check your connection.');
      } else if (e is TimeoutException) {
        throw TimeoutException(message: 'Report loading timed out. Please try again.');
      }

      if (e is AppException) {
        rethrow;
      }
      throw ReportException(
        message: 'Failed to load reports: ${e.toString()}',
        exception: e,
      );
    }
  }

  /// Get a single report by ID
  Future<Report> getReportById(int reportId) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/reports/$reportId'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw ErrorHandler.handleHttpResponse(response);
      }

      return Report.fromJson(jsonDecode(response.body));
    } catch (e) {
      if (e is http.ClientException) {
        throw NetworkException(message: 'Failed to load report details. Please check your connection.');
      } else if (e is TimeoutException) {
        throw TimeoutException(message: 'Report loading timed out. Please try again.');
      }

      if (e is AppException) {
        rethrow;
      }
      throw ReportException(
        message: 'Failed to load report details: ${e.toString()}',
        exception: e,
      );
    }
  }

  /// Generate a new report
  Future<Report> generateReport({
    required ReportType reportType,
    DateTime? startDate,
    DateTime? endDate,
    List<int>? deviceIds,
    bool includeResolvedIssues = false,
  }) async {
    try {
      final requestBody = {
        'report_type': reportType.toString().split('.').last,
        'start_date': (startDate ?? DateTime.now().subtract(const Duration(days: 1))).toIso8601String(),
        'end_date': (endDate ?? DateTime.now()).toIso8601String(),
        if (deviceIds != null) 'device_ids': deviceIds,
        'include_resolved': includeResolvedIssues,
      };

      final response = await _client.post(
        Uri.parse('$_baseUrl/reports/generate'),
        headers: await _getHeaders(),
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode != 200) {
        throw ErrorHandler.handleHttpResponse(response);
      }

      return Report.fromJson(jsonDecode(response.body));
    } catch (e) {
      if (e is http.ClientException) {
        throw NetworkException(message: 'Failed to generate report. Please check your connection.');
      } else if (e is TimeoutException) {
        throw TimeoutException(message: 'Report generation timed out. Please try again.');
      }

      if (e is AppException) {
        rethrow;
      }
      throw ReportException(
        message: 'Failed to generate report: ${e.toString()}',
        exception: e,
      );
    }
  }

  /// Delete a report
  Future<void> deleteReport(int reportId) async {
    try {
      final response = await _client.delete(
        Uri.parse('$_baseUrl/reports/$reportId'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 204) {
        throw ErrorHandler.handleHttpResponse(response);
      }
    } catch (e) {
      if (e is http.ClientException) {
        throw NetworkException(message: 'Failed to delete report. Please check your connection.');
      } else if (e is TimeoutException) {
        throw TimeoutException(message: 'Report deletion timed out. Please try again.');
      }

      if (e is AppException) {
        rethrow;
      }
      throw ReportException(
        message: 'Failed to delete report: ${e.toString()}',
        exception: e,
      );
    }
  }

  /// Get report metrics
  Future<Map<String, dynamic>> getReportMetrics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = {
        if (startDate != null) 'start_date': startDate.toIso8601String(),
        if (endDate != null) 'end_date': endDate.toIso8601String(),
      };

      final uri = Uri.parse('$_baseUrl/reports/metrics').replace(queryParameters: queryParams);

      final response = await _client.get(
        uri,
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw ErrorHandler.handleHttpResponse(response);
      }

      return jsonDecode(response.body);
    } catch (e) {
      if (e is http.ClientException) {
        throw NetworkException(message: 'Failed to fetch metrics. Please check your connection.');
      } else if (e is TimeoutException) {
        throw TimeoutException(message: 'Metrics loading timed out. Please try again.');
      }

      if (e is AppException) {
        rethrow;
      }
      throw ReportException(
        message: 'Failed to fetch metrics: ${e.toString()}',
        exception: e,
      );
    }
  }

  /// Export a report
  Future<void> exportReport(
      int reportId, {
        String format = 'pdf',
        String reportType = 'daily',
      }) async {
    try {
      final queryParams = {
        'format': format,
        'report_type': reportType,
      };

      final uri = Uri.parse('$_baseUrl/reports/$reportId/export').replace(queryParameters: queryParams);

      final response = await _client.get(
        uri,
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw ErrorHandler.handleHttpResponse(response);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'DEFIoT_Security_Report_${reportId}_${reportType}_$timestamp.$format';

      if (kIsWeb) {
        _downloadFileWeb(response.bodyBytes, fileName);
      } else {
        await _downloadFileMobile(response.bodyBytes, fileName);
      }
    } catch (e) {
      if (e is http.ClientException) {
        throw NetworkException(message: 'Failed to export report. Please check your connection.');
      } else if (e is TimeoutException) {
        throw TimeoutException(message: 'Report export timed out. Please try again.');
      }

      if (e is AppException) {
        rethrow;
      }
      throw ReportException(
        message: 'Failed to export report: ${e.toString()}',
        exception: e,
      );
    }
  }

  /// Download file on web platform
  void _downloadFileWeb(List<int> bytes, String fileName) {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  /// Download file on mobile platform
  Future<void> _downloadFileMobile(List<int> bytes, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$fileName';

    // Save file
    final file = File(filePath);
    await file.writeAsBytes(bytes);

    // Open file
    final result = await OpenFile.open(filePath);
    if (result.type != ResultType.done) {
      throw Exception('Failed to open report: ${result.message}');
    }
  }

  /// Get security trends
  Future<Map<String, dynamic>> getSecurityTrends({
    int? days,
    List<int>? deviceIds,
  }) async {
    try {
      final queryParams = {
        if (days != null) 'days': days.toString(),
        if (deviceIds != null) 'device_ids': deviceIds.join(','),
      };

      final uri = Uri.parse('$_baseUrl/reports/trends').replace(queryParameters: queryParams);

      final response = await _client.get(
        uri,
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw ErrorHandler.handleHttpResponse(response);
      }

      return jsonDecode(response.body);
    } catch (e) {
      if (e is http.ClientException) {
        throw NetworkException(message: 'Failed to fetch security trends. Please check your connection.');
      } else if (e is TimeoutException) {
        throw TimeoutException(message: 'Security trends loading timed out. Please try again.');
      }

      if (e is AppException) {
        rethrow;
      }
      throw ReportException(
        message: 'Failed to fetch security trends: ${e.toString()}',
        exception: e,
      );
    }
  }

  /// Schedule automatic report generation
  Future<void> scheduleReport({
    required ReportType reportType,
    required String schedule, // daily, weekly, monthly
    String? email,
    List<int>? deviceIds,
  }) async {
    try {
      final requestBody = {
        'report_type': reportType.toString().split('.').last,
        'schedule': schedule,
        if (email != null) 'email': email,
        if (deviceIds != null) 'device_ids': deviceIds,
      };

      final response = await _client.post(
        Uri.parse('$_baseUrl/reports/schedule'),
        headers: await _getHeaders(),
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw ErrorHandler.handleHttpResponse(response);
      }
    } catch (e) {
      if (e is http.ClientException) {
        throw NetworkException(message: 'Failed to schedule report. Please check your connection.');
      } else if (e is TimeoutException) {
        throw TimeoutException(message: 'Report scheduling timed out. Please try again.');
      }

      if (e is AppException) {
        rethrow;
      }
      throw ReportException(
        message: 'Failed to schedule report: ${e.toString()}',
        exception: e,
      );
    }
  }
}