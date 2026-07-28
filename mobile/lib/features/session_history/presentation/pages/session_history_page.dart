import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../active_game/data/models/session_state.dart';
import '../../../active_game/data/repositories/session_repository.dart';

const _statusLabels = {
  'DRAFT': 'مسودة',
  'WAITING_FOR_PLAYERS': 'بانتظار اللاعبين',
  'READY': 'جاهزة',
  'IN_PROGRESS': 'جارية',
  'PAUSED': 'متوقفة مؤقتًا',
  'COMPLETED': 'مكتملة',
  'CANCELLED': 'ملغاة',
};

const _modeLabels = {
  'MIXED': 'خليط',
  'CATEGORY': 'فئة معيّنة',
  'BEST_CARDS': 'أفضل الكارطات',
  'CUSTOM': 'مخصّصة',
};

class SessionHistoryPage extends ConsumerWidget {
  const SessionHistoryPage({required this.groupId, super.key});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(_historyProvider(groupId));

    return Scaffold(
      appBar: AppBar(title: const Text('الجلسات السابقة')),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (sessions) {
          if (sessions.isEmpty) {
            return const Center(child: Text('ما فماش جلسات قديمة'));
          }

          return ListView.builder(
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              return ListTile(
                leading: const Icon(Icons.style_outlined),
                title: Text(_modeLabels[session.gameMode] ?? session.gameMode),
                subtitle: Text(
                  '${_statusLabels[session.status] ?? session.status} · '
                  '${session.completedCardCount}/${session.requestedCardCount} كارطة',
                ),
                trailing: Text(session.sessionCode),
              );
            },
          );
        },
      ),
    );
  }
}

final _historyProvider =
    FutureProvider.autoDispose.family<List<SessionSummary>, String>((ref, groupId) {
  return ref.watch(sessionRepositoryProvider).listSessions(groupId);
});
