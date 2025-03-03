// lib/services/base_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/exceptions/app_exceptions.dart';
import 'http/api_client.dart';

abstract class BaseService {
  final ApiClient apiClient;

  BaseService({required this.apiClient});

  /// Executes a service method with error handling and result transformation
  Future<T> execute<T>({
    required Future<T> Function() task,
    String? errorMessage,
  }) async {
    try {
      return await task();
    } on ApiException catch (e) {
      if (kDebugMode) {
        print('API Exception: ${e.toString()}');
      }
      rethrow;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error executing service method: $e');
        print('Stack trace: $stackTrace');
      }
      throw UnknownException(errorMessage ?? 'An error occurred: ${e.toString()}');
    }
  }

  /// Transforms API response to a model instance
  T transformResponse<T>(
      dynamic response,
      T Function(Map<String, dynamic> json) transformer,
      ) {
    try {
      if (response == null) {
        throw ParseException('Response is null');
      }

      if (response is Map<String, dynamic>) {
        return transformer(response);
      } else {
        throw ParseException('Response format is not valid');
      }
    } catch (e) {
      throw ParseException('Error transforming response: ${e.toString()}');
    }
  }

  /// Transforms API response to a list of model instances
  List<T> transformResponseList<T>(
      dynamic response,
      T Function(Map<String, dynamic> json) transformer,
      ) {
    try {
      if (response == null) {
        return [];
      }

      if (response is List) {
        return response
            .map((item) => transformer(item as Map<String, dynamic>))
            .toList();
      } else {
        throw ParseException('Response is not a list');
      }
    } catch (e) {
      throw ParseException('Error transforming response list: ${e.toString()}');
    }
  }
}