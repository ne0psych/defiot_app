// lib/services/http/logging_interceptor.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class LoggingInterceptor {
  void logRequest(String method, Uri url, dynamic body) {
    if (kDebugMode) {
      print('┌───────── Request ─────────');
      print('│ $method $url');
      if (body != null) {
        print('│ Body: ${_formatJson(body)}');
      }
      print('└───────────────────────────');
    }
  }

  void logResponse(http.Response response) {
    if (kDebugMode) {
      print('┌───────── Response ────────');
      print('│ ${response.statusCode} ${response.reasonPhrase}');
      print('│ ${_truncateResponseBody(response.body)}');
      print('└───────────────────────────');
    }
  }

  void logError(dynamic error) {
    if (kDebugMode) {
      print('┌───────── Error ──────────');
      print('│ ${error.toString()}');
      print('└───────────────────────────');
    }
  }

  String _formatJson(dynamic json) {
    if (json is Map) {
      // Filter out sensitive data
      final filtered = Map.of(json);
      if (filtered.containsKey('password')) {
        filtered['password'] = '******';
      }
      if (filtered.containsKey('token') || filtered.containsKey('access_token')) {
        filtered['token'] = '******';
        filtered['access_token'] = '******';
      }
      return const JsonEncoder.withIndent('  ').convert(filtered);
    }
    return json.toString();
  }

  String _truncateResponseBody(String body) {
    if (body.isEmpty) return 'Empty response';

    try {
      final jsonBody = json.decode(body);
      final formattedJson = const JsonEncoder.withIndent('  ').convert(jsonBody);

      // Truncate if too long
      if (formattedJson.length > 1000) {
        return '${formattedJson.substring(0, 1000)}... (truncated)';
      }
      return formattedJson;
    } catch (e) {
      // Not valid JSON or other issue
      if (body.length > 500) {
        return '${body.substring(0, 500)}... (truncated)';
      }
      return body;
    }
  }
}