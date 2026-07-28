import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../models/session_state.dart';

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepository(ref.watch(dioProvider));
});

class SessionRepository {
  SessionRepository(this._dio);

  final Dio _dio;

  Future<SessionState> createSession({
    required String groupId,
    required String gameMode,
    String? categoryCode,
    required int requestedCardCount,
    required bool scoringEnabled,
  }) {
    return _post('/sessions', {
      'groupId': groupId,
      'gameMode': gameMode,
      'categoryCode': categoryCode,
      'requestedCardCount': requestedCardCount,
      'scoringEnabled': scoringEnabled,
    });
  }

  Future<SessionState> joinByCode(String sessionCode) {
    return _post('/sessions/join', {'sessionCode': sessionCode});
  }

  Future<SessionState> addParticipant(String sessionId, String userPublicId) {
    return _post('/sessions/$sessionId/participants', {'userPublicId': userPublicId});
  }

  Future<SessionState> getState(String sessionId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/sessions/$sessionId');
      return SessionState.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<SessionState> choosePowerCards(
    String sessionId,
    String participantId,
    List<String> powerCardDefinitionIds,
  ) {
    return _post(
      '/sessions/$sessionId/participants/$participantId/power-cards',
      {'powerCardDefinitionIds': powerCardDefinitionIds},
    );
  }

  Future<SessionState> start(String sessionId) {
    return _post('/sessions/$sessionId/start', const {});
  }

  Future<SessionState> completeCard(String sessionId, String sessionCardId) {
    return _post('/sessions/$sessionId/cards/$sessionCardId/complete', const {});
  }

  Future<SessionState> skipCard(String sessionId, String sessionCardId) {
    return _post('/sessions/$sessionId/cards/$sessionCardId/skip', const {});
  }

  Future<SessionState> usePowerCard(
    String sessionId,
    String assignmentId, {
    String? targetParticipantId,
  }) {
    return _post(
      '/sessions/$sessionId/power-cards/$assignmentId/use',
      {'targetParticipantId': targetParticipantId},
    );
  }

  Future<SessionState> awardScore(
    String sessionId, {
    required String participantId,
    required int points,
    required String reasonCode,
    String? note,
  }) {
    return _post('/sessions/$sessionId/scores', {
      'participantId': participantId,
      'points': points,
      'reasonCode': reasonCode,
      'note': note,
    });
  }

  Future<SessionState> pause(String sessionId) => _post('/sessions/$sessionId/pause', const {});

  Future<SessionState> resume(String sessionId) => _post('/sessions/$sessionId/resume', const {});

  Future<SessionState> cancel(String sessionId) => _post('/sessions/$sessionId/cancel', const {});

  Future<List<SessionSummary>> listSessions(String groupId) async {
    try {
      final response = await _dio.get<List<dynamic>>('/groups/$groupId/sessions');
      return response.data!
          .map((json) => SessionSummary.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<SessionState> _post(String path, Map<String, dynamic> data) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(path, data: data);
      return SessionState.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
