import 'package:dio/dio.dart';

/// Mirrors the backend's `ErrorResponse` body so UI code can branch on a
/// stable `code` instead of parsing HTTP status codes or messages.
class ApiException implements Exception {
  const ApiException({
    required this.status,
    required this.code,
    required this.message,
  });

  factory ApiException.fromDioException(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      return ApiException(
        status: (data['status'] as num?)?.toInt() ?? error.response?.statusCode ?? 0,
        code: data['code'] as String? ?? 'UNKNOWN_ERROR',
        message: data['message'] as String? ?? error.message ?? 'Unexpected error',
      );
    }

    return ApiException(
      status: error.response?.statusCode ?? 0,
      code: 'NETWORK_ERROR',
      message: error.message ?? 'Network error',
    );
  }

  final int status;
  final String code;
  final String message;

  bool get isConflict => status == 409;
  bool get isUnauthorized => status == 401;

  @override
  String toString() => 'ApiException($code: $message)';
}
