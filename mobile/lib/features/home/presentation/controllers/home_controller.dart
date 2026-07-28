import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../groups/data/models/group.dart';
import '../../../groups/data/repositories/group_repository.dart';

/// v0 is a single private family group seeded server-side on first boot, so
/// the home screen just shows the first (and only) group the player belongs to.
final myGroupProvider = FutureProvider.autoDispose<Group?>((ref) async {
  final groups = await ref.watch(groupRepositoryProvider).listMyGroups();
  return groups.isEmpty ? null : groups.first;
});
