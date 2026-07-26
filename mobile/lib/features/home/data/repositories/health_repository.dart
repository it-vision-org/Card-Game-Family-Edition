import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';

final healthRepositoryProvider = Provider<HealthRepository>((ref) {
  return HealthRepository(ref.watch(dioProvider));
});

class HealthRepository {
  HealthRepository(this._dio);

  final Dio _dio;

  Future<String> checkBackend() async {
    final response = await _dio.get<Map<String, dynamic>>('/health');

    final data = response.data;

    if (data == null || data['status'] == null) {
      throw const FormatException('Invalid backend health response');
    }

    return data['status'] as String;
  }
}