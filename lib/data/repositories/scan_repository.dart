import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../local/shared_prefs.dart';
import '../../core/exceptions/app_exceptions.dart';
import '../../core/exceptions/error_handler.dart';
import '../../models/scan_model.dart';
import '../../models/device_model.dart';
import '../../models/vulnerability_model.dart';
import '../../core/constants/app_constants.dart';

/// Repository class that handles scan operations
class ScanRepository {
  final http.Client _client;
  final String _baseUrl;

  ScanRepository({
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

  /// Get all scans with optional filtering
  Future<List<Scan>> getScans({
    int? deviceId,
    String? scanType,
    DateTime? startDate,
    DateTime? endDate,
    int skip = 0,
    int limit = 20,
  }) async {
    try {
      final queryParams = {
        'skip': skip.toString(),
        'limit': limit.toString(),
        if (deviceId != null) 'device_id': deviceId.toString(),
        if (scanType != null) 'scan_type': scanType,
        if (startDate != null) 'start_date': startDate.toIso8601String(),
        if (endDate != null) 'end_date': endDate.toIso8601String(),
      };

      final uri = Uri.parse('$_baseUrl/scans').replace(queryParameters: queryParams);

      final response = await _client.get(
        uri,
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw ErrorHandler.handleHttpResponse(response);
      }

      final List<dynamic> scanData = jsonDecode(response.body);
      return scanData.map((data) => Scan.fromJson(data)).toList();
    } catch (e) {
      if (e is http.ClientException) {
        throw NetworkException(message: 'Failed to load scans. Please check your connection.');
      } else if (e is TimeoutException) {
        throw TimeoutException(message: 'Scan loading timed out. Please try again.');
      }

      if (e is AppException) {
        rethrow;
      }
      throw ScanException(
        message: 'Failed to load scans: ${e.toString()}',
        exception: e,
      );
    }
  }

  /// Get a single scan by ID
  Future<Scan> getScan(int scanId) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/scans/$scanId'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw ErrorHandler.handleHttpResponse(response);
      }

      return Scan.fromJson(jsonDecode(response.body));
    } catch (e) {
      if (e is http.ClientException) {
        throw NetworkException(message: 'Failed to load scan details. Please check your connection.');
      } else if (e is TimeoutException) {
        throw TimeoutException(message: 'Scan loading timed out. Please try again.');
      }

      if (e is AppException) {
        rethrow;
      }
      throw ScanException(
        message: 'Failed to load scan details: ${e.toString()}',
        exception: e,
      );
    }
  }

  /// Create a new scan
  Future<Scan?> createScan({
    required int deviceId,
    required String scanType,
    Map<String, dynamic>? customOptions,
  }) async {
    try {
      // First, fetch device info to check if it's simulated
      final deviceResponse = await _client.get(
        Uri.parse('$_baseUrl/devices/$deviceId'),
        headers: await _getHeaders(),
      );

      if (deviceResponse.statusCode != 200) {
        throw ErrorHandler.handleHttpResponse(deviceResponse);
      }

      final device = Device.fromJson(jsonDecode(deviceResponse.body));

      // Determine if device is simulated
      final isSimulated = device.securityDetails['simulation_mode'] == true ||
          (device.firmwareVersion == null || device.firmwareVersion!.isEmpty);

      final body = {
        'device_id': deviceId,
        'scan_type': scanType,
        'custom_options': {
          ...?customOptions,
          'is_simulated': isSimulated,
          'device_type': device.deviceType,
          'ip_address': device.ipAddress,
        },
      };

      final response = await _client.post(
        Uri.parse('$_baseUrl/scans'),
        headers: await _getHeaders(),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode != 201 && response.statusCode != 200) {
        throw ErrorHandler.handleHttpResponse(response);
      }

      // Record the scan time for this device
      await SharedPrefs.saveLastScanTime(deviceId, DateTime.now());

      return Scan.fromJson(jsonDecode(response.body));
    } catch (e) {
      if (e is http.ClientException) {
        throw NetworkException(message: 'Failed to create scan. Please check your connection.');
      } else if (e is TimeoutException) {
        throw TimeoutException(message: 'Scan creation timed out. Please try again.');
      }

      if (e is AppException) {
        rethrow;
      }
      throw ScanException(
        message: 'Failed to create scan: ${e.toString()}',
        exception: e,
      );
    }
  }

  /// Get simulated scan results (for simulated devices)
  Future<Map<String, dynamic>?> getSimulatedScanResults(int deviceId) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/devices/$deviceId/simulated-scan-results'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return null;
      }

      return jsonDecode(response.body);
    } catch (e) {
      // Return null on error, not critical
      return null;
    }
  }

  /// Update scan results (used for simulated devices)
  Future<Scan?> updateScanResults(
      int scanId,
      Map<String, dynamic> scanResults,
      ) async {
    try {
      final response = await _client.put(
        Uri.parse('$_baseUrl/scans/$scanId/results'),
        headers: await _getHeaders(),
        body: jsonEncode(scanResults),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return null;
      }

      return Scan.fromJson(jsonDecode(response.body));
    } catch (e) {
      // Return null on error, not critical
      return null;
    }
  }

  /// Cancel an in-progress scan
  Future<void> cancelScan(int scanId) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/scans/$scanId/cancel'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw ErrorHandler.handleHttpResponse(response);
      }
    } catch (e) {
      if (e is http.ClientException) {
        throw NetworkException(message: 'Failed to cancel scan. Please check your connection.');
      } else if (e is TimeoutException) {
        throw TimeoutException(message: 'Scan cancellation timed out. Please try again.');
      }

      if (e is AppException) {
        rethrow;
      }
      throw ScanException(
        message: 'Failed to cancel scan: ${e.toString()}',
        exception: e,
      );
    }
  }

  /// Get vulnerabilities from a scan
  Future<List<Vulnerability>> getVulnerabilities(
      int scanId, {
        String? severity,
        String? type,
        int skip = 0,
        int limit = 50,
      }) async {
    try {
      final queryParams = {
        if (severity != null) 'severity': severity,
        if (type != null) 'type': type,
        'skip': skip.toString(),
        'limit': limit.toString(),
      };

      final uri = Uri.parse('$_baseUrl/scans/$scanId/vulnerabilities')
          .replace(queryParameters: queryParams);

      final response = await _client.get(
        uri,
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw ErrorHandler.handleHttpResponse(response);
      }

      final List<dynamic> vulnData = jsonDecode(response.body);
      return vulnData.map((data) => Vulnerability.fromJson(data)).toList();
    } catch (e) {
      if (e is http.ClientException) {
        throw NetworkException(message: 'Failed to load vulnerabilities. Please check your connection.');
      } else if (e is TimeoutException) {
        throw TimeoutException(message: 'Vulnerability loading timed out. Please try again.');
      }

      if (e is AppException) {
        rethrow;
      }
      throw VulnerabilityException(
        message: 'Failed to load vulnerabilities: ${e.toString()}',
        exception: e,
      );
    }
  }

  /// Export a scan report
  Future<void> exportScan(
      int scanId, {
        String format = 'pdf',
      }) async {
    try {
      final queryParams = {'format': format};

      final uri = Uri.parse('$_baseUrl/scans/$scanId/export')
          .replace(queryParameters: queryParams);

      final response = await _client.get(
        uri,
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        throw ErrorHandler.handleHttpResponse(response);
      }

      // Handle download (implementation depends on platform)
      // The file itself is contained in response.bodyBytes
    } catch (e) {
      if (e is http.ClientException) {
        throw NetworkException(message: 'Failed to export scan. Please check your connection.');
      } else if (e is TimeoutException) {
        throw TimeoutException(message: 'Scan export timed out. Please try again.');
      }

      if (e is AppException) {
        rethrow;
      }
      throw ScanException(
        message: 'Failed to export scan: ${e.toString()}',
        exception: e,
      );
    }
  }

  /// Get device security metrics
  Future<Map<String, dynamic>> getDeviceSecurityMetrics(int deviceId) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/devices/$deviceId/security-metrics'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw ErrorHandler.handleHttpResponse(response);
      }

      return jsonDecode(response.body);
    } catch (e) {
      if (e is http.ClientException) {
        throw NetworkException(message: 'Failed to load security metrics. Please check your connection.');
      } else if (e is TimeoutException) {
        throw TimeoutException(message: 'Security metrics loading timed out. Please try again.');
      }

      if (e is AppException) {
        rethrow;
      }
      throw DeviceException(
        message: 'Failed to load security metrics: ${e.toString()}',
        exception: e,
      );
    }
  }

  /// Create batch scans for multiple devices
  Future<List<Scan>> createBatchScans(
      List<Device> devices,
      String scanType, {
        Map<String, dynamic>? customOptions,
      }) async {
    final List<Scan> completedScans = [];

    for (var device in devices) {
      try {
        if (device.ipAddress.isEmpty) {
          continue; // Skip devices without IP address
        }

        final scan = await createScan(
          deviceId: device.id,
          scanType: scanType,
          customOptions: customOptions ?? {'timeout': 120},
        );

        if (scan != null) {
          completedScans.add(scan);
        }
      } catch (e) {
        // Log error but continue with other devices
        ErrorHandler.logError(e);
      }
    }

    return completedScans;
  }

  /// Check if a device has been scanned recently
  bool hasRecentScan(int deviceId, {int hours = 24}) {
    final lastScan = SharedPrefs.getLastScanTime(deviceId);
    if (lastScan == null) {
      return false;
    }

    final now = DateTime.now();
    final difference = now.difference(lastScan);
    return difference.inHours < hours;
  }
}