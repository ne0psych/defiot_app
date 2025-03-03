// lib/services/scan_service.dart
import 'dart:async';
import '../models/scan_model.dart';
import '../models/vulnerability_model.dart';
import 'base_service.dart';
import 'http/api_client.dart';

class ScanService extends BaseService {
  static const String _baseEndpoint = '/scans';

  ScanService({required ApiClient apiClient}) : super(apiClient: apiClient);

  Future<List<Scan>> getScans({
    int? deviceId,
    String? scanType,
    DateTime? startDate,
    DateTime? endDate,
    int skip = 0,
    int limit = 20,
  }) async {
    return execute<List<Scan>>(
      task: () async {
        final queryParams = {
          if (deviceId != null) 'device_id': deviceId.toString(),
          if (scanType != null) 'scan_type': scanType,
          if (startDate != null) 'start_date': startDate.toIso8601String(),
          if (endDate != null) 'end_date': endDate.toIso8601String(),
          'skip': skip.toString(),
          'limit': limit.toString(),
        };

        final response = await apiClient.get(
          _baseEndpoint,
          queryParams: queryParams,
        );

        return transformResponseList(response, Scan.fromJson);
      },
      errorMessage: 'Failed to fetch scans',
    );
  }

  Future<Scan> getScan(int scanId) async {
    return execute<Scan>(
      task: () async {
        final response = await apiClient.get('$_baseEndpoint/$scanId');
        return transformResponse(response, Scan.fromJson);
      },
      errorMessage: 'Failed to fetch scan details',
    );
  }

  Future<Scan> createScan({
    required int deviceId,
    required String scanType,
    Map<String, dynamic>? customOptions,
  }) async {
    return execute<Scan>(
      task: () async {
        final body = {
          'device_id': deviceId,
          'scan_type': scanType,
          if (customOptions != null) 'custom_options': customOptions,
        };

        final response = await apiClient.post(
          _baseEndpoint,
          body: body,
          timeout: const Duration(seconds: 60), // Increased timeout for scan creation
        );

        return transformResponse(response, Scan.fromJson);
      },
      errorMessage: 'Failed to create scan',
    );
  }

  Future<List<Scan>> createBatchScans(
      List<int> deviceIds,
      String scanType, {
        Map<String, dynamic>? customOptions,
      }) async {
    return execute<List<Scan>>(
      task: () async {
        final body = {
          'device_ids': deviceIds,
          'scan_type': scanType,
          if (customOptions != null) 'custom_options': customOptions,
        };

        final response = await apiClient.post(
          '$_baseEndpoint/batch',
          body: body,
          timeout: const Duration(seconds: 120), // Increased timeout for batch scanning
        );

        return transformResponseList(response, Scan.fromJson);
      },
      errorMessage: 'Failed to start batch scan',
    );
  }

  Future<Scan?> updateScanResults(
      int scanId,
      Map<String, dynamic> scanResults,
      ) async {
    return execute<Scan?>(
      task: () async {
        final response = await apiClient.put(
          '$_baseEndpoint/$scanId/results',
          body: scanResults,
        );

        if (response == null) return null;
        return transformResponse(response, Scan.fromJson);
      },
      errorMessage: 'Failed to update scan results',
    );
  }

  Future<void> cancelScan(int scanId) async {
    return execute<void>(
      task: () async {
        await apiClient.post('$_baseEndpoint/$scanId/cancel');
        return;
      },
      errorMessage: 'Failed to cancel scan',
    );
  }

  Future<Map<String, dynamic>?> getSimulatedScanResults(int deviceId) async {
    return execute<Map<String, dynamic>?>(
      task: () async {
        final response = await apiClient.get('/devices/$deviceId/simulated-scan-results');
        return response as Map<String, dynamic>?;
      },
      errorMessage: 'Failed to get simulated scan results',
    );
  }

  Future<List<Vulnerability>> getVulnerabilities(
      int scanId, {
        String? severity,
        String? type,
        int skip = 0,
        int limit = 50,
      }) async {
    return execute<List<Vulnerability>>(
      task: () async {
        final queryParams = {
          if (severity != null) 'severity': severity,
          if (type != null) 'type': type,
          'skip': skip.toString(),
          'limit': limit.toString(),
        };

        final response = await apiClient.get(
          '$_baseEndpoint/$scanId/vulnerabilities',
          queryParams: queryParams,
        );

        return transformResponseList(response, Vulnerability.fromJson);
      },
      errorMessage: 'Failed to get vulnerabilities',
    );
  }

  Future<void> exportScan(
      int scanId, {
        String format = 'pdf',
      }) async {
    return execute<void>(
      task: () async {
        final queryParams = {'format': format};

        await apiClient.get(
          '$_baseEndpoint/$scanId/export',
          queryParams: queryParams,
        );

        return;
      },
      errorMessage: 'Failed to export scan',
    );
  }
}