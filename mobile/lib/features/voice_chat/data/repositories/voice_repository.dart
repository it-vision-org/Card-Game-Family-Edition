import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../models/voice_credentials.dart';

final voiceRepositoryProvider = Provider<VoiceRepository>((ref) {
  return VoiceRepository(ref.watch(dioProvider));
});

class VoiceRepository {
  VoiceRepository(this._dio);

  final Dio _dio;

  /// Asks the backend to mint a short-lived LiveKit room-access token for
  /// this session. The backend verifies the caller is actually a participant
  /// in [sessionId] before issuing one — the LiveKit API secret never leaves
  /// the server.
  Future<VoiceCredentials> fetchToken(String sessionId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/sessions/$sessionId/voice/token',
      );
      return VoiceCredentials.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
