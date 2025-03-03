// lib/providers/device_provider.dart
import 'package:flutter/foundation.dart';
import '../models/device_model.dart';
import '../models/vulnerability_model.dart';
import '../services/device_service.dart';
import '../core/exceptions/app_exceptions.dart';

class DeviceProvider with ChangeNotifier {
  final DeviceService _deviceService;
  List<Device> _devices = [];
  bool _isLoading = false;
  String? _error;
  Map<int, List<Vulnerability>> _deviceVulnerabilities = {};
  Map<int, bool> _deviceLoadingStates = {};

  DeviceProvider({required DeviceService deviceService})
      : _deviceService = deviceService;

  // Getters
  List<Device> get devices => _devices;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Device> getDevicesByRiskLevel(RiskLevel riskLevel) {
    return _devices.where((device) => device.riskLevel == riskLevel).toList();
  }

  bool isDeviceLoading(int deviceId) => _deviceLoadingStates[deviceId] ?? false;

  List<Vulnerability>? getDeviceVulnerabilities(int deviceId) =>
      _deviceVulnerabilities[deviceId];

  Future<void> loadDevices({
    String? deviceType,
    DeviceStatus? status,
    String? searchQuery,
    RiskLevel? minRiskLevel,
    int skip = 0,
    int limit = 100,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      _devices = await _deviceService.getDevices(
        deviceType: deviceType,
        status: status,
        searchQuery: searchQuery,
        minRiskLevel: minRiskLevel,
        skip: skip,
        limit: limit,
      );

      // Check if devices list is empty
      if (_devices.isEmpty) {
        _error = 'No devices found. Please add a device first.';
      }
    } catch (e) {
      _error = _formatError(e);
      _devices = [];
    } finally {
      _setLoading(false);
    }
  }

  Future<Device?> addDevice({
    required String deviceName,
    String? deviceType,
    required String macAddress,
    String? ipAddress,
    String? firmwareVersion,
  }) async {
    try {
      final device = await _deviceService.createDevice(
        deviceName: deviceName,
        deviceType: deviceType,
        macAddress: macAddress,
        ipAddress: ipAddress,
        firmwareVersion: firmwareVersion,
      );

      _devices.add(device);
      notifyListeners();
      return device;
    } catch (e) {
      _error = _formatError(e);
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateDevice(
      int deviceId, {
        String? deviceName,
        String? deviceType,
        String? ipAddress,
        String? firmwareVersion,
        DeviceStatus? status,
        Map<String, dynamic>? securityDetails,
      }) async {
    try {
      final updatedDevice = await _deviceService.updateDevice(
        deviceId,
        deviceName: deviceName,
        deviceType: deviceType,
        ipAddress: ipAddress,
        firmwareVersion: firmwareVersion,
        status: status,
        securityDetails: securityDetails,
      );

      final index = _devices.indexWhere((d) => d.id == deviceId);
      if (index != -1) {
        _devices[index] = updatedDevice;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = _formatError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteDevice(int deviceId) async {
    try {
      await _deviceService.deleteDevice(deviceId);
      _devices.removeWhere((d) => d.id == deviceId);
      _deviceVulnerabilities.remove(deviceId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = _formatError(e);
      notifyListeners();
      return false;
    }
  }

  Future<void> loadDeviceVulnerabilities(
      int deviceId, {
        String? severity,
        String? status,
      }) async {
    _deviceLoadingStates[deviceId] = true;
    notifyListeners();

    try {
      final vulnerabilities = await _deviceService.getDeviceVulnerabilities(
        deviceId,
        severity: severity,
        status: status,
      );

      _deviceVulnerabilities[deviceId] = vulnerabilities;
      _error = null;
    } catch (e) {
      _error = _formatError(e);
      _deviceVulnerabilities[deviceId] = [];
    } finally {
      _deviceLoadingStates[deviceId] = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> getDeviceSecurityMetrics(int deviceId) async {
    try {
      return await _deviceService.getDeviceSecurityMetrics(deviceId);
    } catch (e) {
      _error = _formatError(e);
      notifyListeners();
      rethrow;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void selectDevice(Device device, bool selected) {
    device.isSelected = selected;
    notifyListeners();
  }

  void selectAllDevices(bool selected) {
    _devices = _devices.map((d) => d.copyWith(isSelected: selected)).toList();
    notifyListeners();
  }

  String _formatError(dynamic error) {
    if (error is ApiException) {
      return error.message;
    }

    if (error is Exception) {
      return error.toString().replaceAll('Exception: ', '');
    }

    return error.toString();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}