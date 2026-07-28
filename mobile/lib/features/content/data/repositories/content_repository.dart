import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/network/api_client.dart';
import '../models/card_category.dart';
import '../models/power_card_definition.dart';

final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  return ContentRepository(ref.watch(dioProvider), ref.watch(appDatabaseProvider));
});

class ContentRepository {
  ContentRepository(this._dio, this._db);

  final Dio _dio;
  final AppDatabase _db;

  Future<List<CardCategory>> listCategories() async {
    try {
      final response = await _dio.get<List<dynamic>>('/cards/categories');
      final categories = response.data!
          .map((json) => CardCategory.fromJson(json as Map<String, dynamic>))
          .toList();

      await _db.replaceCategories(
        categories
            .map((c) => CachedCategoriesCompanion.insert(code: c.code, sortOrder: c.sortOrder))
            .toList(),
      );

      return categories;
    } on DioException {
      final cached = await _db.allCategories();
      return cached.map((row) => CardCategory(code: row.code, sortOrder: row.sortOrder)).toList();
    }
  }

  Future<List<PowerCardDefinition>> listPowerCards() async {
    final response = await _dio.get<List<dynamic>>('/power-cards');
    return response.data!
        .map((json) => PowerCardDefinition.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
