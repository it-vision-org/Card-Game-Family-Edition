import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../content/data/models/card_category.dart';
import '../../../content/data/repositories/content_repository.dart';
import '../../data/models/my_card.dart';
import '../../data/repositories/my_card_repository.dart';

final myCardsProvider = FutureProvider.autoDispose<List<MyCard>>((ref) {
  return ref.watch(myCardRepositoryProvider).listMyCards();
});

final cardCategoriesProvider = FutureProvider.autoDispose<List<CardCategory>>((
  ref,
) {
  return ref.watch(contentRepositoryProvider).listCategories();
});
