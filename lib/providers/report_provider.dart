// lib/providers/report_provider.dart
import 'package:flutter/foundation.dart';
import '../models/report_model.dart';
import '../services/report_service.dart';
import '../core/exceptions/app_exceptions.dart';

class ReportProvider with ChangeNotifier {
  final ReportService _reportService;
  List<Report> _reports = [];
  bool _isLoading = false;
  String? _error;

  ReportProvider({required ReportService reportService})
      : _reportService = reportService;

  // Getters
  List<Report> get reports => _reports;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchReports({
    ReportType reportType = ReportType.daily,
    DateTime? startDate,
    DateTime? endDate,
    int skip = 0,
    int limit = 7,
  }) async {
    _setLoading(true);

    try {
      _reports = await _reportService.getReports(
        reportType: reportType,
        startDate: startDate,
        endDate: endDate,
        skip: skip,
        limit: limit,
      );
      _error = null;
    } catch (e) {
      _error = _formatError(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<Report?> generateReport({
    required ReportType reportType,
    DateTime? startDate,
    DateTime? endDate,
    List<int>? deviceIds,
    bool includeResolvedIssues = false,
  }) async {
    _setLoading(true);

    try {
      if (kDebugMode) {
        print('Generating Report with Parameters:');
        print('Report Type: $reportType');
        print('Start Date: $startDate');
        print('End Date: $endDate');
      }

      final report = await _reportService.generateReport(
        reportType: reportType,
        startDate: startDate ?? DateTime.now().subtract(const Duration(days: 1)),
        endDate: endDate ?? DateTime.now(),
        deviceIds: deviceIds,
        includeResolvedIssues: includeResolvedIssues,
      );

      if (kDebugMode) {
        print('Report Generated Successfully: ${report.reportId}');
      }

      // Add the new report to the top of the list
      _reports.insert(0, report);
      _error = null;
      notifyListeners();
      return report;
    } catch (e) {
      if (kDebugMode) {
        print('Detailed Error Generating Report:');
        print('Error: $e');
      }
      _error = _formatError(e);
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<Report?> fetchReportById(int reportId) async {
    _setLoading(true);

    try {
      final report = await _reportService.getReportById(reportId);
      _error = null;
      return report;
    } catch (e) {
      _error = _formatError(e);
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteReport(int reportId) async {
    _setLoading(true);

    try {
      await _reportService.deleteReport(reportId);
      _reports.removeWhere((report) => report.reportId == reportId);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = _formatError(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> getReportMetrics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return await _reportService.getReportMetrics(
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      _error = _formatError(e);
      rethrow;
    }
  }

  Future<void> exportReport(
      int reportId, {
        String format = 'pdf',
        String reportType = 'daily',
      }) async {
    _setLoading(true);

    try {
      await _reportService.exportReport(
        reportId,
        format: format.toLowerCase(),
        reportType: reportType,
      );
      _error = null;
    } catch (e) {
      _error = _formatError(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> getSecurityTrends({
    int? days,
    List<int>? deviceIds,
  }) async {
    try {
      return await _reportService.getSecurityTrends(
        days: days,
        deviceIds: deviceIds,
      );
    } catch (e) {
      _error = _formatError(e);
      rethrow;
    }
  }

  void clearError() {
    _error = null;
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