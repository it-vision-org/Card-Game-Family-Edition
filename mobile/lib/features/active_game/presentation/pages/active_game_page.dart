import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../voice_chat/presentation/widgets/voice_chat_controls.dart';
import '../../data/models/session_state.dart';
import '../controllers/session_controller.dart';
import '../widgets/card_timer.dart';
import '../widgets/game_card_widget.dart';
import '../widgets/power_card_tray.dart';
import '../widgets/sequential_card_timer.dart';
import '../widgets/turn_indicator.dart';

const _scoreReasons = [
  ('CORRECT_GUESS', 'توقّع صحيح'),
  ('MADE_EVERYONE_LAUGH', 'ضحك الكل'),
  ('REMEMBERED_DETAIL', 'تذكّر تفصيل قديم'),
  ('HONEST_ANSWER', 'إجابة صادقة ومؤثرة'),
  ('CHALLENGE_SUCCESS', 'نجح في تحدّي'),
];

class ActiveGamePage extends ConsumerWidget {
  const ActiveGamePage({required this.sessionId, super.key});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(sessionControllerProvider(sessionId));
    final controller = ref.read(sessionControllerProvider(sessionId).notifier);
    final currentUser = ref.watch(authControllerProvider).value;

    ref.listen(sessionControllerProvider(sessionId), (previous, next) {
      final session = next.value;
      if (session == null) return;

      if (session.status == 'COMPLETED') {
        context.pushReplacement('/session/$sessionId/results');
      }

      final previousSession = previous?.value;
      if (previousSession == null) return;
      if (!session.isMultiDevice) return;

      final myUserId = ref.read(authControllerProvider).value?.id;
      for (final participant in session.participants) {
        if (participant.userId == myUserId) continue;
        final previousParticipant = _participantById(
          previousSession.participants,
          participant.id,
        );
        if (previousParticipant == null) continue;

        for (final assignment in participant.powerCards) {
          if (!assignment.used) continue;
          final wasAlreadyUsed =
              _assignmentById(
                previousParticipant.powerCards,
                assignment.id,
              )?.used ??
              false;
          if (!wasAlreadyUsed && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${participant.displayName} استعمل بطاقة "${assignment.title}"',
                ),
              ),
            );
          }
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('الجلسة جارية'),
        actions: [
          VoiceChatControls(
            sessionId: sessionId,
            enabled: sessionAsync.value?.isMultiDevice ?? false,
          ),
          if (sessionAsync.value?.scoringEnabled == true)
            IconButton(
              tooltip: 'منح نقطة',
              icon: const Icon(Icons.emoji_events_outlined),
              onPressed: () => _showAwardScoreDialog(
                context,
                ref,
                sessionAsync.value!.participants,
              ),
            ),
          IconButton(
            tooltip: sessionAsync.value?.status == 'PAUSED'
                ? 'كمّل'
                : 'وقّف مؤقتًا',
            icon: Icon(
              sessionAsync.value?.status == 'PAUSED'
                  ? Icons.play_arrow
                  : Icons.pause,
            ),
            onPressed: () => _handle(
              context,
              sessionAsync.value?.status == 'PAUSED'
                  ? controller.resume()
                  : controller.pause(),
            ),
          ),
        ],
      ),
      body: sessionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (session) {
          final card = session.currentCard;
          final playersOnTurn = session.participants
              .where((p) => p.currentTurn)
              .toList();
          final currentTurnParticipant = playersOnTurn.isEmpty
              ? null
              : playersOnTurn.first;
          final isMultiDevice = session.isMultiDevice;
          // In single-device mode (one phone passed around the table), the
          // logged-in user isn't necessarily whoever's turn it is — so show
          // whichever participant is currently up, same as before this
          // feature existed. In real multi-device mode, always show this
          // device's own participant's power cards.
          final myParticipant = isMultiDevice
              ? (currentUser == null
                    ? null
                    : _participantByUserId(
                        session.participants,
                        currentUser.id,
                      ))
              : currentTurnParticipant;
          final isMyTurn =
              !isMultiDevice ||
              (currentTurnParticipant != null &&
                  myParticipant != null &&
                  currentTurnParticipant.id == myParticipant.id);

          return Column(
            children: [
              TurnIndicator(
                participants: session.participants,
                scoringEnabled: session.scoringEnabled,
              ),
              LinearProgressIndicator(
                value: session.requestedCardCount == 0
                    ? 0
                    : session.completedCardCount / session.requestedCardCount,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '${session.completedCardCount} / ${session.requestedCardCount} كارطة',
                ),
              ),
              if (session.status == 'PAUSED')
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    'الجلسة متوقفة مؤقتًا',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (card != null) GameCardWidget(card: card),
                      if (card?.timerSeconds != null) ...[
                        const SizedBox(height: 12),
                        if (card!.answerMode == 'ALL_PLAYERS_SEQUENTIALLY')
                          SequentialCardTimer(
                            key: ValueKey(card.sessionCardId),
                            sessionCardId: card.sessionCardId,
                            seconds: card.timerSeconds!,
                            participantCount: session.participants.length,
                          )
                        else
                          CardTimer(
                            sessionCardId: card.sessionCardId,
                            seconds: card.timerSeconds!,
                          ),
                      ],
                      const SizedBox(height: 20),
                      if (myParticipant != null)
                        PowerCardTray(
                          participant: myParticipant,
                          onUse: (assignment) => _handle(
                            context,
                            controller.usePowerCard(assignment.id),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (card != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      if (card.skippable)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isMyTurn
                                ? () => _handle(
                                    context,
                                    controller.skipCurrentCard(
                                      card.sessionCardId,
                                    ),
                                  )
                                : null,
                            child: const Text('تجاوز'),
                          ),
                        ),
                      if (card.skippable) const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: isMyTurn
                              ? () => _handle(
                                  context,
                                  controller.completeCurrentCard(
                                    card.sessionCardId,
                                  ),
                                )
                              : null,
                          child: const Text('تمّت'),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handle(BuildContext context, Future<void> future) async {
    try {
      await future;
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _showAwardScoreDialog(
    BuildContext context,
    WidgetRef ref,
    List<Participant> participants,
  ) async {
    Participant? selected = participants.isEmpty ? null : participants.first;
    String reasonCode = _scoreReasons.first.$1;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('منح نقطة'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    children: participants.map((p) {
                      return ChoiceChip(
                        label: Text(p.displayName),
                        selected: selected?.id == p.id,
                        onSelected: (_) => setState(() => selected = p),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  RadioGroup<String>(
                    groupValue: reasonCode,
                    onChanged: (value) => setState(() => reasonCode = value!),
                    child: Column(
                      children: _scoreReasons.map((reason) {
                        final (code, label) = reason;
                        return RadioListTile<String>(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(label),
                          value: code,
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  onPressed: selected == null
                      ? null
                      : () {
                          Navigator.of(dialogContext).pop();
                          _handle(
                            context,
                            ref
                                .read(
                                  sessionControllerProvider(sessionId).notifier,
                                )
                                .awardScore(
                                  participantId: selected!.id,
                                  points: 1,
                                  reasonCode: reasonCode,
                                ),
                          );
                        },
                  child: const Text('منح'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

Participant? _participantByUserId(
  List<Participant> participants,
  String userId,
) {
  for (final participant in participants) {
    if (participant.userId == userId) return participant;
  }
  return null;
}

Participant? _participantById(List<Participant> participants, String id) {
  for (final participant in participants) {
    if (participant.id == id) return participant;
  }
  return null;
}

PowerCardAssignment? _assignmentById(
  List<PowerCardAssignment> assignments,
  String id,
) {
  for (final assignment in assignments) {
    if (assignment.id == id) return assignment;
  }
  return null;
}
