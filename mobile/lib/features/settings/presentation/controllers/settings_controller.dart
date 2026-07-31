import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/game_settings.dart';
import '../../data/models/trash_entry.dart';
import '../../data/repositories/settings_repository.dart';

final gameSettingsProvider = FutureProvider.autoDispose<GameSettings>((ref) {
  return ref.watch(settingsRepositoryProvider).getGameSettings();
});

final trashProvider = FutureProvider.autoDispose
    .family<List<TrashEntry>, String>((ref, groupId) {
      return ref.watch(settingsRepositoryProvider).listTrash(groupId);
    });
