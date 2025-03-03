// lib/providers/scan_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/scan_model.dart';
import '../models/device_model.dart';
import '../models/vulnerability_model.dart';
import '../services/scan_service.dart';
import '../providers/report_provider.dart';
import '../core/exceptions/app_exceptions.dart';

class ScanProvider with ChangeNotifier {
  final ScanService _scanService;
  final ReportProvider _reportProvider;

  Map<int, List<Scan>> _deviceScans = {};
  List<Scan> _allScans = [];
  Map<int, Scan?> _latestScans = {};
  bool _isLoading = false;
  String? _error;
  double _batchProgress = 0.0;
  bool _disposed = false;
  Map<int, bool> _deviceScanningStates = {};
  Timer? _scanStatusTimer;

  ScanProvider({
    required ScanService scanService,
    required ReportProvider reportProvider,
  })  : _scanService = scanService,
        _reportProvider = reportProvider;

  // Getters
  List<Scan> get scans => _allScans;
  List<Scan> getDeviceScans(int deviceId) => _deviceScans[deviceId] ?? [];
  Scan? getLatestScan(int deviceId) => _latestScans[deviceId];
  bool isDeviceScanning(int deviceId) => _deviceScanningStates[deviceId] ?? false;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get batchProgress => _batchProgress;

  @override
  void dispose() {
    _scanStatusTimer?.cancel();
    _disposed = true;
    super.dispose();
  }

  void cleanup() {
    if (_disposed) return;
    _deviceScans.clear();
    _latestScans.clear();
    _allScans.clear();
    _isLoading = false;
    _error = null;
    _batchProgress = 0.0;
    notifyListeners();
  }

  Future<void> loadScans({
    int? deviceId,
    String? scanType,
    DateTime? startDate,
    DateTime? endDate,
    int skip = 0,
    int limit = 20,
  }) async {
    _setLoading(true);

    try {
      final loadedScans = await _scanService.getScans(
        deviceId: deviceId,
        scanType: scanType,
        startDate: startDate,
        endDate: endDate,
        skip: skip,
        limit: limit,
      );

      if (deviceId != null) {
        _deviceScans[deviceId] = loadedScans;
        _updateLatestScan(deviceId, loadedScans);
      }

      // Update the all scans list
      _allScans = loadedScans;
      _error = null;
    } catch (e) {
      _error = _formatError(e);
      if (deviceId != null) {
        _deviceScans[deviceId] = [];
      }
      _allScans = [];
    } finally {
      _setLoading(false);
    }
  }

  Future<Scan?> getScan(int scanId) async {
    try {
      final scan = await _scanService.getScan(scanId);
      _error = null;
      return scan;
    } catch (e) {
      _error = _formatError(e);
      return null;
    }
  }

  Future<Scan?> createScan({
    required int deviceId,
    required String scanType,
    Map<String, dynamic>? customOptions,
  }) async {
    _deviceScanningStates[deviceId] = true;
    notifyListeners();

    try {
      final scan = await _scanService.createScan(
        deviceId: deviceId,
        scanType: scanType,
        customOptions: {
          ...?customOptions,
          'timeout': 120,
        },
      );

      // Update device scans list
      if (!_deviceScans.containsKey(deviceId)) {
        _deviceScans[deviceId] = [];
      }
      _deviceScans[deviceId]!.insert(0, scan);
      _updateLatestScan(deviceId, [scan]);

      // Update all scans list
      _allScans.insert(0, scan);

      _error = null;
      notifyListeners();
      return scan;
    } catch (e) {
      if (kDebugMode) {
        print('Detailed scan creation error: $e');
      }
      _error = _formatError(e);
      return null;
    } finally {
      _deviceScanningStates[deviceId] = false;
      notifyListeners();
    }
  }

  Future<List<Scan>> createBatchScans(
      List<Device> devices,
      String scanType, {
        Map<String, dynamic>? customOptions,
      }) async {
    if (_disposed) return [];

    final List<Scan> completedScans = [];
    _setError(null);
    _setLoading(true);
    _batchProgress = 0.0;

    try {
      final selectedDevices = devices.where((d) => d.isSelected).toList();
      if (selectedDevices.isEmpty) {
        _setError('No devices selected for scanning');
        return [];
      }

      int totalDevices = selectedDevices.length;
      int processed = 0;

      // Extract device IDs for batch scanning
      final deviceIds = selectedDevices.map((device) => device.id).toList();

      // Use the batch scan API if available
      try {
        final batchScans = await _scanService.createBatchScans(
          deviceIds,
          scanType,
          customOptions: customOptions,
        );

        if (batchScans.isNotEmpty) {
          // Update local data structures
          for (var scan in batchScans) {
            if (!_deviceScans.containsKey(scan.deviceId)) {
              _deviceScans[scan.deviceId] = [];
            }
            _deviceScans[scan.deviceId]!.insert(0, scan);
            _updateLatestScan(scan.deviceId, [scan]);
          }

          _allScans.insertAll(0, batchScans);
          completedScans.addAll(batchScans);
          _batchProgress = 1.0;
          notifyListeners();
        }
      } catch (e) {
        // Fallback to individual scans if batch scanning fails
        if (kDebugMode) {
          print('Batch scanning failed, falling back to individual scans: $e');
        }

        for (var device in selectedDevices) {
          try {
            if (device.ipAddress.isEmpty) {
              if (kDebugMode) {
                print('Skipping device ${device.deviceName}: No IP address');
              }
              processed++;
              _batchProgress = processed / totalDevices;
              notifyListeners();
              continue;
            }

            final scan = await createScan(
              deviceId: device.id,
              scanType: scanType,
              customOptions: {'timeout': 120},
            );

            if (scan != null) {
              completedScans.add(scan);
            }
          } catch (e) {
            if (kDebugMode) {
              print('Error scanning device ${device.deviceName}: $e');
            }
          } finally {
            processed++;
            _batchProgress = processed / totalDevices;
            notifyListeners();
          }
        }
      }

      // Generate a report if scans were successful
      try {
        if (completedScans.isNotEmpty) {
          await _reportProvider.generateReport(
            reportType: ReportType.daily,
            startDate: DateTime.now().subtract(const Duration(days: 1)),
            endDate: DateTime.now(),
            deviceIds: completedScans.map((scan) => scan.deviceId).toList(),
          );
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error generating report after batch scans: $e');
        }
      }

      return completedScans;
    } catch (e) {
      _setError('Failed to start batch scans: ${_formatError(e)}');
      return completedScans;
    } finally {
      _setLoading(false);
      _batchProgress = 0.0;
      notifyListeners();
    }
  }

  Future<void> cancelScan(int scanId) async {
    try {
      await _scanService.cancelScan(scanId);
      _error = null;

      // Update scan status in local state
      for (var deviceId in _deviceScans.keys) {
        final scanIndex = _deviceScans[deviceId]?.indexWhere((s) => s.scanId == scanId) ?? -1;
        if (scanIndex != -1) {
          _deviceScans[deviceId]![scanIndex] = _deviceScans[deviceId]![scanIndex].copyWith(
            status: ScanStatus.failed,
          );

          // Also update in the all scans list
          final allScansIndex = _allScans.indexWhere((s) => s.scanId == scanId);
          if (allScansIndex != -1) {
            _allScans[allScansIndex] = _allScans[allScansIndex].copyWith(
              status: ScanStatus.failed,
            );
          }

          notifyListeners();
          break;
        }
      }
    } catch (e) {
      _error = _formatError(e);
    }
  }

  Future<List<Vulnerability>> getVulnerabilities(
      int scanId, {
        String? severity,
        String? type,
        int skip = 0,
        int limit = 50,
      }) async {
    try {
      return await _scanService.getVulnerabilities(
        scanId,
        severity: severity,
        type: type,
        skip: skip,
        limit: limit,
      );
    } catch (e) {
      _error = _formatError(e);
      rethrow;
    }
  }

  Future<void> exportScan(int scanId, {String format = 'pdf'}) async {
    try {
      await _scanService.exportScan(scanId, format: format);
    } catch (e) {
      _error = _formatError(e);
      rethrow;
    }
  }

  void _updateLatestScan(int deviceId, List<Scan> scans) {
    if (scans.isNotEmpty) {
      final latestScan = scans.reduce((curr, next) =>
      curr.createdAt.isAfter(next.createdAt) ? curr : next);
      _latestScans[deviceId] = latestScan;
    }
  }

  void _updateScanInLists(Scan updatedScan) {
    // Update in device scans
    final deviceScans = _deviceScans[updatedScan.deviceId];
    if (deviceScans != null) {
      final index = deviceScans.indexWhere((s) => s.scanId == updatedScan.scanId);
      if (index != -1) {
        deviceScans[index] = updatedScan;
      }
    }

    // Update in all scans
    final allScansIndex = _allScans.indexWhere((s) => s.scanId == updatedScan.scanId);
    if (allScansIndex != -1) {
      _allScans[allScansIndex] = updatedScan;
    }

    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _error = message;
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

  void clearError() {
    _error = null;
    notifyListeners();
  }
}