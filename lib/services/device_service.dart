// lib/services/device_service.dart
import 'dart:async';
import '../models/device_model.dart';
import '../models/vulnerability_model.dart';
import 'base_service.dart';
import 'http/api_client.dart';

class DeviceService extends BaseService {
  static const String _baseEndpoint = '/devices';

  DeviceService({required ApiClient apiClient}) : super(apiClient: apiClient);

  Future<List<Device>> getDevices({
    String? deviceType,
    DeviceStatus? status,
    String? searchQuery,
    RiskLevel? minRiskLevel,
    int skip = 0,
    int limit = 100,
  }) async {
    return execute<List<Device>>(
      task: () async {
        final queryParams = {
          'skip': skip.toString(),
          'limit': limit.toString(),
          if (deviceType != null) 'device_type': deviceType,
          if (status != null) 'status': status.toString().split('.').last,
          if (searchQuery != null) 'search': searchQuery,
          if (minRiskLevel != null) 'min_risk_level': minRiskLevel.toString().split('.').last,
        };

        final response = await apiClient.get(
          _baseEndpoint,
          queryParams: queryParams,
        );

        return transformResponseList(response, Device.fromJson);
      },
      errorMessage: 'Failed to fetch devices',
    );
  }

  Future<Device> getDevice(int deviceId) async {
    return execute<Device>(
      task: () async {
        final response = await apiClient.get('$_baseEndpoint/$deviceId');
        return transformResponse(response, Device.fromJson);
      },
      errorMessage: 'Failed to fetch device details',
    );
  }

  Future<Device> createDevice({
    required String deviceName,
    String? deviceType,
    required String macAddress,
    String? ipAddress,
    String? firmwareVersion,
  }) async {
    return execute<Device>(
      task: () async {
        final body = {
          'device_name': deviceName,
          'device_type': deviceType,
          'mac_address': macAddress,
          'ip_address': ipAddress,
          if (firmwareVersion != null) 'firmware_version': firmwareVersion,
        };

        final response = await apiClient.post(
          _baseEndpoint,
          body: body,
        );

        return transformResponse(response, Device.fromJson);
      },
      errorMessage: 'Failed to create device',
    );
  }

  Future<Device> updateDevice(
      int deviceId, {
        String? deviceName,
        String? deviceType,
        String? ipAddress,
        String? firmwareVersion,
        DeviceStatus? status,
        Map<String, dynamic>? securityDetails,
      }) async {
    return execute<Device>(
      task: () async {
        final body = {
          if (deviceName != null) 'device_name': deviceName,
          if (deviceType != null) 'device_type': deviceType,
          if (ipAddress != null) 'ip_address': ipAddress,
          if (firmwareVersion != null) 'firmware_version': firmwareVersion,
          if (status != null) 'status': status.toString().split('.').last,
          if (securityDetails != null) 'security_details': securityDetails,
        };

        final response = await apiClient.put(
          '$_baseEndpoint/$deviceId',
          body: body,
        );

        return transformResponse(response, Device.fromJson);
      },
      errorMessage: 'Failed to update device',
    );
  }

  Future<void> deleteDevice(int deviceId) async {
    return execute<void>(
      task: () async {
        await apiClient.delete('$_baseEndpoint/$deviceId');
        return;
      },
      errorMessage: 'Failed to delete device',
    );
  }

  Future<List<Vulnerability>> getDeviceVulnerabilities(
      int deviceId, {
        String? severity,
        String? status,
        int skip = 0,
        int limit = 50,
      }) async {
    return execute<List<Vulnerability>>(
      task: () async {
        final queryParams = {
          if (severity != null) 'severity': severity,
          if (status != null) 'status': status,
          'skip': skip.toString(),
          'limit': limit.toString(),
        };

        final response = await apiClient.get(
          '$_baseEndpoint/$deviceId/vulnerabilities',
          queryParams: queryParams,
        );

        return transformResponseList(response, Vulnerability.fromJson);
      },
      errorMessage: 'Failed to fetch device vulnerabilities',
    );
  }

  Future<Map<String, dynamic>> getDeviceSecurityMetrics(int deviceId) async {
    return execute<Map<String, dynamic>>(
      task: () async {
        final response = await apiClient.get(
          '$_baseEndpoint/$deviceId/security-metrics',
        );

        if (response is Map<String, dynamic>) {
          return response;
        } else {
          throw Exception('Invalid response format');
        }
      },
      errorMessage: 'Failed to fetch device security metrics',
    );
  }
}