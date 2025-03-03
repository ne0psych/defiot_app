// lib/services/report_service.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:html' as html;

import '../models/report_model.dart';
import 'base_service.dart';
import 'http/api_client.dart';

class ReportService extends BaseService {
  static const String _baseEndpoint = '/reports';

  ReportService({required ApiClient apiClient}) : super(apiClient: apiClient);

  Future<List<Report>> getReports({
    required ReportType reportType,
    DateTime? startDate,
    DateTime? endDate,
    int skip = 0,
    int limit = 7,
  }) async {
    return execute<List<Report>>(
      task: () async {
        final queryParams = {
          'report_type': reportType.toString().split('.').last,
          'skip': skip.toString(),
          'limit': limit.toString(),
          if (startDate != null) 'start_date': startDate.toIso8601String(),
          if (endDate != null) 'end_date': endDate.toIso8601String(),
        };

        final response = await apiClient.get(
          _baseEndpoint,
          queryParams: queryParams,
        );

        return transformResponseList(response, Report.fromJson);
      },
      errorMessage: 'Failed to fetch reports',
    );
  }

  Future<Report> getReportById(int reportId) async {
    return execute<Report>(
      task: () async {
        final response = await apiClient.get('$_baseEndpoint/$reportId');
        return transformResponse(response, Report.fromJson);
      },
      errorMessage: 'Failed to fetch report details',
    );
  }

  Future<Report> generateReport({
    required ReportType reportType,
    DateTime? startDate,
    DateTime? endDate,
    List<int>? deviceIds,
    bool includeResolvedIssues = false,
  }) async {
    return execute<Report>(
      task: () async {
        final body = {
          'report_type': reportType.toString().split('.').last,
          'start_date': (startDate ?? DateTime.now().subtract(const Duration(days: 1))).toIso8601String(),
          'end_date': (endDate ?? DateTime.now()).toIso8601String(),
          if (deviceIds != null) 'device_ids': deviceIds,
          'include_resolved': includeResolvedIssues,
        };

        final response = await apiClient.post(
          '$_baseEndpoint/generate',
          body: body,
          timeout: const Duration(seconds: 60),
        );

        return transformResponse(response, Report.fromJson);
      },
      errorMessage: 'Failed to generate report',
    );
  }

  Future<void> deleteReport(int reportId) async {
    return execute<void>(
      task: () async {
        await apiClient.delete('$_baseEndpoint/$reportId');
        return;
      },
      errorMessage: 'Failed to delete report',
    );
  }

  Future<Map<String, dynamic>> getReportMetrics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return execute<Map<String, dynamic>>(
      task: () async {
        final queryParams = {
          if (startDate != null) 'start_date': startDate.toIso8601String(),
          if (endDate != null) 'end_date': endDate.toIso8601String(),
        };

        final response = await apiClient.get(
          '$_baseEndpoint/metrics',
          queryParams: queryParams,
        );

        if (response is Map<String, dynamic>) {
          return response;
        } else {
          throw Exception('Invalid response format');
        }
      },
      errorMessage: 'Failed to fetch report metrics',
    );
  }

  Future<void> exportReport(
      int reportId, {
        String format = 'pdf',
        String reportType = 'daily',
      }) async {
    return execute<void>(
      task: () async {
        final queryParams = {
          'format': format,
          'report_type': reportType,
        };

        final response = await apiClient.get(
          '$_baseEndpoint/$reportId/export',
          queryParams: queryParams,
        );

        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'DEFIoT_Security_Report_${reportId}_${reportType}_$timestamp.$format';

        if (kIsWeb) {
          try {
            // Handle web download
            final blob = html.Blob([response]);
            final url = html.Url.createObjectUrlFromBlob(blob);
            final anchor = html.AnchorElement(href: url)
              ..setAttribute('download', fileName)
              ..click();
            html.Url.revokeObjectUrl(url);
          } catch (webError) {
            throw Exception('Failed to download report in browser: $webError');
          }
        } else {
          try {
            // Mobile platform handling
            final directory = await getApplicationDocumentsDirectory();
            final filePath = '${directory.path}/$fileName';

            // Save file
            final file = File(filePath);
            await file.writeAsBytes(response);

            // Open file
            final result = await OpenFile.open(filePath);
            if (result.type != ResultType.done) {
              throw Exception('Failed to open report: ${result.message}');
            }
          } catch (mobileError) {
            throw Exception('Failed to save or open report on device: $mobileError');
          }
        }

        return;
      },
      errorMessage: 'Failed to export report',
    );
  }

  Future<Map<String, dynamic>> getSecurityTrends({
    int? days,
    List<int>? deviceIds,
  }) async {
    return execute<Map<String, dynamic>>(
      task: () async {
        final queryParams = {
          if (days != null) 'days': days.toString(),
          if (deviceIds != null) 'device_ids': deviceIds.join(','),
        };

        final response = await apiClient.get(
          '$_baseEndpoint/trends',
          queryParams: queryParams,
        );

        if (response is Map<String, dynamic>) {
          return response;
        } else {
          throw Exception('Invalid response format');
        }
      },
      errorMessage: 'Failed to fetch security trends',
    );
  }
}