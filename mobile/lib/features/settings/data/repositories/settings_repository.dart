import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../models/game_settings.dart';
import '../models/trash_entry.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(dioProvider));
});

class SettingsRepository {
  SettingsRepository(this._dio);

  final Dio _dio;

  Future<GameSettings> getGameSettings() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/game-settings');
      return GameSettings.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<GameSettings> updatePowerCardsPerPlayer(int value) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/admin/game-settings',
        data: {'powerCardsPerPlayer': value},
      );
      return GameSettings.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<TrashEntry>> listTrash(String groupId) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/admin/groups/$groupId/trash',
      );
      return response.data!
          .map((json) => TrashEntry.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> restoreCard(String groupId, String cardId) async {
    try {
      await _dio.post<void>('/admin/groups/$groupId/trash/$cardId/restore');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> restoreCardsBulk(String groupId, List<String> cardIds) async {
    try {
      await _dio.post<void>(
        '/admin/groups/$groupId/trash/restore-bulk',
        data: {'cardIds': cardIds},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
