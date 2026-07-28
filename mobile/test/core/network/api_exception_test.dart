import 'package:between_three_mobile/core/network/api_exception.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiException.fromDioException', () {
    test('parses the backend ErrorResponse body', () {
      final requestOptions = RequestOptions(path: '/sessions/123/start');
      final dioException = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 409,
          data: {
            'status': 409,
            'code': 'NOT_ENOUGH_PLAYERS',
            'message': 'At least two players are required to start a session',
          },
        ),
      );

      final apiException = ApiException.fromDioException(dioException);

      expect(apiException.status, 409);
      expect(apiException.code, 'NOT_ENOUGH_PLAYERS');
      expect(apiException.isConflict, isTrue);
      expect(apiException.isUnauthorized, isFalse);
    });

    test('falls back to a network error when there is no response body', () {
      final requestOptions = RequestOptions(path: '/auth/login');
      final dioException = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.connectionError,
        message: 'Connection refused',
      );

      final apiException = ApiException.fromDioException(dioException);

      expect(apiException.code, 'NETWORK_ERROR');
      expect(apiException.message, 'Connection refused');
    });
  });
}
