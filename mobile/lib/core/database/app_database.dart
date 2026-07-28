import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'app_database.g.dart';

/// Local cache of card/category content, used only so the mode picker and
/// (briefly) the active game screen have something to show through a short
/// connectivity drop. This app is online-first by design (sessions always
/// live on the backend); this is a cache, not an offline-first sync store.
class CachedCategories extends Table {
  TextColumn get code => text()();
  IntColumn get sortOrder => integer()();

  @override
  Set<Column> get primaryKey => {code};
}

class CachedCards extends Table {
  TextColumn get id => text()();
  TextColumn get externalKey => text()();
  TextColumn get type => text()();
  TextColumn get categoryCode => text().nullable()();
  BoolColumn get best => boolean().withDefault(const Constant(false))();
  BoolColumn get skippable => boolean().withDefault(const Constant(true))();
  BoolColumn get supportsScoring => boolean().withDefault(const Constant(false))();
  IntColumn get sensitivityLevel => integer().withDefault(const Constant(1))();
  IntColumn get emotionalDepth => integer().withDefault(const Constant(1))();
  IntColumn get timerSeconds => integer().nullable()();
  TextColumn get targetingJson => text().withDefault(const Constant('{}'))();
  TextColumn get title => text().nullable()();
  TextColumn get cardText => text().withDefault(const Constant(''))();
  TextColumn get instructions => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [CachedCategories, CachedCards])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  Future<void> replaceCategories(List<CachedCategoriesCompanion> categories) {
    return transaction(() async {
      await delete(cachedCategories).go();
      await batch((batch) => batch.insertAll(cachedCategories, categories));
    });
  }

  Future<void> replaceCards(List<CachedCardsCompanion> cards) {
    return transaction(() async {
      await delete(cachedCards).go();
      await batch((batch) => batch.insertAll(cachedCards, cards));
    });
  }

  Future<List<CachedCategory>> allCategories() {
    return (select(cachedCategories)
          ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
        .get();
  }

  Future<List<CachedCard>> allCards() => select(cachedCards).get();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'between_three_cache.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
