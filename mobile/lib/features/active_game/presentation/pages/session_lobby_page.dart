import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../home/presentation/controllers/home_controller.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../../voice_chat/presentation/widgets/voice_chat_controls.dart';
import '../controllers/session_controller.dart';
import '../widgets/power_card_picker_dialog.dart';

class SessionLobbyPage extends ConsumerStatefulWidget {
  const SessionLobbyPage({required this.sessionId, super.key});

  final String sessionId;

  @override
  ConsumerState<SessionLobbyPage> createState() => _SessionLobbyPageState();
}

class _SessionLobbyPageState extends ConsumerState<SessionLobbyPage> {
  bool _startingSession = false;
  final Set<String> _submittingParticipantIds = {};

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(sessionControllerProvider(widget.sessionId));
    final groupAsync = ref.watch(myGroupProvider);
    final gameSettingsAsync = ref.watch(gameSettingsProvider);

    ref.listen(sessionControllerProvider(widget.sessionId), (previous, next) {
      final session = next.value;
      if (session != null && session.status == 'IN_PROGRESS') {
        context.pushReplacement('/session/${widget.sessionId}/play');
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('غرفة الانتظار'),
        actions: [
          VoiceChatControls(
            sessionId: widget.sessionId,
            enabled: sessionAsync.value?.isMultiDevice ?? false,
          ),
        ],
      ),
      body: sessionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (session) {
          final joinedPublicIds = session.participants
              .map((p) => p.publicId)
              .toSet();
          final missingMembers =
              groupAsync.value?.members
                  .where((m) => !joinedPublicIds.contains(m.publicId))
                  .toList() ??
              const [];
          final requiredPowerCards =
              gameSettingsAsync.value?.powerCardsPerPlayer ?? 0;

          final playersStillPicking = session.participants
              .where((p) => p.powerCards.length != requiredPowerCards)
              .map((p) => p.displayName)
              .toList();
          final canStart =
              session.participants.length >= 2 && playersStillPicking.isEmpty;

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'كود الجلسة',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  session.sessionCode,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.displaySmall?.copyWith(letterSpacing: 4),
                ),
                const SizedBox(height: 24),
                Text(
                  'اللاعبين',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ...session.participants.map((p) {
                  final isSubmitting = _submittingParticipantIds.contains(p.id);
                  return ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(p.displayName),
                    subtitle: requiredPowerCards > 0
                        ? Text(
                            'بطاقات القوة: ${p.powerCards.length} / $requiredPowerCards',
                          )
                        : null,
                    trailing: requiredPowerCards > 0
                        ? (isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : TextButton(
                                  onPressed: () => _choosePowerCards(
                                    p.id,
                                    p.displayName,
                                    requiredPowerCards,
                                  ),
                                  child: const Text('اختار البطاقات'),
                                ))
                        : null,
                  );
                }),
                if (missingMembers.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'ضيف لاعب (نفس الهاتف)',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Wrap(
                    spacing: 8,
                    children: missingMembers.map((member) {
                      return ActionChip(
                        avatar: const Icon(Icons.add, size: 18),
                        label: Text(member.displayName),
                        onPressed: () async {
                          try {
                            await ref
                                .read(
                                  sessionControllerProvider(
                                    widget.sessionId,
                                  ).notifier,
                                )
                                .addParticipant(member.publicId);
                          } on ApiException catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.message)),
                              );
                            }
                          }
                        },
                      );
                    }).toList(),
                  ),
                ],
                const Spacer(),
                if (!canStart && playersStillPicking.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'لازال ينتظرو: ${playersStillPicking.join('، ')}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                FilledButton(
                  onPressed: !canStart || _startingSession ? null : _start,
                  child: _startingSession
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('ابدأ اللعب'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _choosePowerCards(
    String participantId,
    String participantName,
    int requiredCount,
  ) async {
    final ids = await showPowerCardPickerDialog(
      context,
      participantName: participantName,
      requiredCount: requiredCount,
    );
    if (ids == null || !mounted) return;

    setState(() => _submittingParticipantIds.add(participantId));
    try {
      await ref
          .read(sessionControllerProvider(widget.sessionId).notifier)
          .choosePowerCards(participantId, ids);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) {
        setState(() => _submittingParticipantIds.remove(participantId));
      }
    }
  }

  Future<void> _start() async {
    setState(() => _startingSession = true);
    try {
      await ref
          .read(sessionControllerProvider(widget.sessionId).notifier)
          .start();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) {
        setState(() => _startingSession = false);
      }
    }
  }
}
