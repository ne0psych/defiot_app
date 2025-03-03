import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../local/shared_prefs.dart';
import '../../core/exceptions/app_exceptions.dart';
import '../../core/exceptions/error_handler.dart';
import '../../models/device_model.dart';
import '../../models/vulnerability_model.dart';
import '../../core/constants/app_constants.dart';

/// Repository class that handles device operations
class DeviceRepository {
  final http.Client _client;
  final String _baseUrl;

  DeviceRepository({
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

  /// Get all devices with optional filtering
  Future<List<Device>> getDevices({
    String? deviceType,
    DeviceStatus? status,
    String? searchQuery,
    RiskLevel? minRiskLevel,
    int skip = 0,
    int limit = 100,
    bool forceRefresh = false,
  }) async {
    try {
      // Check cache first if we're not forcing a refresh
      if (!forceRefresh) {
        final cachedDevices = SharedPrefs.getCachedDevices();
        if (cachedDevices != null) {
          final devices = cachedDevices
              .map((json) => Device.fromJson(json))
              .toList();

          // Apply filters
          return _filterDevices(
            devices,
            deviceType: deviceType,
            status: status,
            searchQuery: searchQuery,
            minRiskLevel: minRiskLevel,
          );
        }
      }

      // Build query parameters
      final queryParams = {
        'skip': skip.toString(),
        'limit': limit.toString(),
        if (deviceType != null) 'device_type': deviceType,
        if (status != null) 'status': status.toString().split('.').last,
        if (searchQuery != null) 'search': searchQuery,
        if (minRiskLevel != null) 'min_risk_level': minRiskLevel.toString().split('.').last,
      };

      final uri = Uri.parse('$_baseUrl/devices').replace(queryParameters: queryParams);

      final response = await _client.get(
        uri,
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw ErrorHandler.handleHttpResponse(response);
      }

      final List<dynamic> devicesJson = jsonDecode(response.body);
      final devices = devicesJson.map((json) => Device.fromJson(json)).toList();

      // Cache the full device list
      await SharedPrefs.cacheDevices(devicesJson);

      return devices;
    } catch (e) {
      if (e is http.ClientException) {
        throw NetworkException(message: 'Failed to load devices. Please check your connection.');
      } else if (e is TimeoutException) {
        throw TimeoutException(message: 'Device loading timed out. Please try again.');
      }

      // Rethrow if it's already an AppException, otherwise wrap it
      if (e is AppException) {
        rethrow;
      }
      throw DeviceException(
        message: 'Failed to load devices: ${e.toString()}',
        exception: e,
      );
    }
  }

  /// Helper method to filter devices locally
  List<Device> _filterDevices(
      List<Device> devices, {
        String? deviceType,
        DeviceStatus? status,
        String? searchQuery,
        RiskLevel? minRiskLevel,
      }) {
    return devices.where((device) {
      if (deviceType != null && device.deviceType != deviceType) {
        return false;
      }

      if (status != null && device.status != status) {
        return false;
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final deviceName = device.deviceName.toLowerCase();
        final deviceIp = device.ipAddress.toLowerCase();
        final deviceMac = device.macAddress.toLowerCase();

        if (!deviceName.contains(query) && !deviceIp.contains(query) && !deviceMac.contains(query)) {
          return false;
        }
      }

      if (minRiskLevel != null) {
        final deviceRiskValue = _getRiskLevelValue(device.riskLevel);
        final minRiskValue = _getRiskLevelValue(minRiskLevel);

        if (deviceRiskValue < minRiskValue) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Helper method to convert risk levels to numeric values for comparison
  int _getRiskLevelValue(RiskLevel level) {
    switch (level) {
      case RiskLevel.critical:
        return 4;
      case RiskLevel.high:
        return 3;
      case RiskLevel.medium:
        return 2;
      case RiskLevel.low:
        return 1;
      default:
        return 0;
    }
  }

  /// Get a single device by ID
  Future<Device> getDevice(int deviceId) async {
    try {
      // Check cache first
      final cachedDevices = SharedPrefs.getCachedDevices();
      if (cachedDevices != null) {
        final deviceJson = cachedDevices.firstWhere(
              (json) => json['id'] == deviceId || json['device_id'] == deviceId,
          orElse: () => null,
        );

        if (deviceJson != null) {
          return Device.fromJson(deviceJson);
        }
      }

      final response = await _client.get(
        Uri.parse('$_baseUrl/devices/$deviceId'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw ErrorHandler.handleHttpResponse(response);
      }

      return Device.fromJson(jsonDecode(response.body));
    } catch (e) {
      if (e is http.ClientException) {
        throw NetworkException(message: 'Failed to load device details. Please check your connection.');
      } else if (e is TimeoutException) {
        throw TimeoutException(message: 'Device loading timed out. Please try again.');
      }

      if (e is AppException) {
        rethrow;
      }
      throw DeviceException(
        message: 'Failed to load device details: ${e.toString()}',
        exception: e,
      );
    }
  }

  /// Create a new device
  Future<Device> createDevice({
    required String deviceName,
    String? deviceType,
    required String macAddress,
    String? ipAddress,
    String? firmwareVersion,
  }) async {
    try {
      final body = {
        'device_name': deviceName,
        'device_type': deviceType,
        'mac_address': macAddress,
        'ip_address': ipAddress,
        if (firmwareVersion != null) 'firmware_version': firmwareVersion,
      };

      final response = await _client.post(
        Uri.parse('$_baseUrl/devices'),
        headers: await _getHeaders(),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 201) {
        throw ErrorHandler.handleHttpResponse(response);
      }

      final device = Device.fromJson(jsonDecode(response.body));

      // Update device cache
      final cachedDevices = SharedPrefs.getCachedDevices();
      if (cachedDevices != null) {
        cachedDevices.add(device.toJson());
        await SharedPrefs.cacheDevices(cachedDevices);
      }

      return device;
    } catch (e) {
      if (e is http.ClientException) {
        throw NetworkException(message: 'Failed to create device. Please check your connection.');
      } else if (e is TimeoutException) {
        throw TimeoutException(message: 'Device creation timed out. Please try again.');
      }

      if (e is AppException) {
        rethrow;
      }
      throw DeviceException(
        message: 'Failed to create device: ${e.toString()}',
        exception: e,
      );
    }
  }

  /// Update a device
  Future<Device> updateDevice(
      int deviceId, {
        String? deviceName,
        String? deviceType,
        String? ipAddress,
        String? firmwareVersion,
        DeviceStatus? status,
        Map<String, dynamic>? securityDetails,
      }) async {
    try {
      final updateData = {
        if (deviceName != null) 'device_name': deviceName,
        if (deviceType != null) 'device_type': deviceType,
        if (ipAddress != null) 'ip_address': ipAddress,
        if (firmwareVersion != null) 'firmware_version': firmwareVersion,
        if (status != null) 'status': status.toString().split('.').last,
        if (securityDetails != null) 'security_details': securityDetails,
      };

      final response = await _client.put(
        Uri.parse('$_baseUrl/devices/$deviceId'),
        headers: await _getHeaders(),
        body: jsonEncode(updateData),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw ErrorHandler.handleHttpResponse(response);
      }

      final updatedDevice = Device.fromJson(jsonDecode(response.body));

      // Update device in cache
      final cachedDevices = SharedPrefs.getCachedDevices();
      if (cachedDevices != null) {
        final index = cachedDevices.indexWhere(
              (json) => json['id'] == deviceId || json['device_id'] == deviceId,
        );

        if (index != -1) {
          cachedDevices[index] = updatedDevice.toJson();
          await SharedPrefs.cacheDevices(cachedDevices);
        }
      }

      return updatedDevice;
    } catch (e) {
      if (e is http.ClientException) {
        throw NetworkException(message: 'Failed to update device. Please check your connection.');
      } else if (e is TimeoutException) {
        throw TimeoutException(message: 'Device update timed out. Please try again.');
      }

      if (e is AppException) {
        rethrow;
      }
      throw DeviceException(
        message: 'Failed to update device: ${e.toString()}',
        exception: e,
      );
    }
  }

  /// Delete a device
  Future<void> deleteDevice(int deviceId) async {
    try {
      final response = await _client.delete(
        Uri.parse('$_baseUrl/devices/$deviceId'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 204) {
        throw ErrorHandler.handleHttpResponse(response);
      }

      // Remove device from cache
      final cachedDevices = SharedPrefs.getCachedDevices();
      if (cachedDevices != null) {
        cachedDevices.removeWhere(
              (json) => json['id'] == deviceId || json['device_id'] == deviceId,
        );
        await SharedPrefs.cacheDevices(cachedDevices);
      }
    } catch (e) {
      if (e is http.ClientException) {
        throw NetworkException(message: 'Failed to delete device. Please check your connection.');
      } else if (e is TimeoutException) {
        throw TimeoutException(message: 'Device deletion timed out. Please try again.');
      }

      if (e is AppException) {
        rethrow;
      }
      throw DeviceException(
        message: 'Failed to delete device: ${e.toString()}',
        exception: e,
      );
    }
  }

  /// Get device vulnerabilities
  Future<List<Vulnerability>> getDeviceVulnerabilities(
      int deviceId, {
        String? severity,
        String? status,
        int skip = 0,
        int limit = 50,
      }) async {
    try {
      final queryParams = {
        if (severity != null) 'severity': severity,
        if (status != null) 'status': status,
        'skip': skip.toString(),
        'limit': limit.toString(),
      };

      final uri = Uri.parse('$_baseUrl/devices/$deviceId/vulnerabilities')
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

  /// Check if a device is simulated
  Future<bool> isDeviceSimulated(int deviceId) async {
    try {
      final device = await getDevice(deviceId);
      return device.securityDetails['simulation_mode'] ?? false;
    } catch (e) {
      // Default to non-simulated if there's an error
      return false;
    }
  }
}