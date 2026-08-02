import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../models/my_card.dart';

final myCardRepositoryProvider = Provider<MyCardRepository>((ref) {
  return MyCardRepository(ref.watch(dioProvider));
});

class MyCardRepository {
  MyCardRepository(this._dio);

  final Dio _dio;

  Future<List<MyCard>> listMyCards() async {
    try {
      final response = await _dio.get<List<dynamic>>('/my-cards');
      return response.data!
          .map((json) => MyCard.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> createCard({
    required String categoryCode,
    required String text,
    required List<String> eligiblePlayerPublicIds,
    required bool best,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/my-cards',
        data: {
          'categoryCode': categoryCode,
          'text': text,
          'eligiblePlayerPublicIds': eligiblePlayerPublicIds,
          'best': best,
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> updateCard({
    required String cardId,
    required String categoryCode,
    required String text,
    required List<String> eligiblePlayerPublicIds,
    required bool best,
  }) async {
    try {
      await _dio.put<Map<String, dynamic>>(
        '/my-cards/$cardId',
        data: {
          'categoryCode': categoryCode,
          'text': text,
          'eligiblePlayerPublicIds': eligiblePlayerPublicIds,
          'best': best,
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> deleteCard(String cardId) async {
    try {
      await _dio.delete<void>('/my-cards/$cardId');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
