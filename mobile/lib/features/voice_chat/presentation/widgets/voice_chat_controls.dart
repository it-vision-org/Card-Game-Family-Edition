import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/voice_controller.dart';

/// Speaker + mic toggle buttons for the voice-chat feature. Meant to sit in
/// an `AppBar.actions` on both the lobby and active-game screens — both
/// screens pass the same [sessionId], so they share the same underlying
/// [voiceControllerProvider] instance (and thus the same LiveKit room
/// connection) via Riverpod's family caching.
///
/// [enabled] should be `session.isMultiDevice` — when `false` (everyone
/// playing on one shared phone), this never touches
/// [voiceControllerProvider] at all, so there's no connection attempt and no
/// loading spinner: just two static, inert icons.
class VoiceChatControls extends ConsumerWidget {
  const VoiceChatControls({
    required this.sessionId,
    required this.enabled,
    super.key,
  });

  final String sessionId;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!enabled) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'المكالمة الصوتية متوفرة بين أجهزة متعددة فقط',
            icon: Icon(Icons.volume_off),
            onPressed: null,
          ),
          IconButton(
            tooltip: 'المكالمة الصوتية متوفرة بين أجهزة متعددة فقط',
            icon: Icon(Icons.mic_off),
            onPressed: null,
          ),
        ],
      );
    }

    final voiceAsync = ref.watch(voiceControllerProvider(sessionId));
    final controller = ref.read(voiceControllerProvider(sessionId).notifier);

    ref.listen(voiceControllerProvider(sessionId), (previous, next) {
      final state = next.value;
      if (state == null) return;

      if (state.micPermissionDenied &&
          previous?.value?.micPermissionDenied != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لازم تسمح بالوصول للميكروفون باش تحكي'),
          ),
        );
      }
      if (state.errorMessage != null &&
          state.errorMessage != previous?.value?.errorMessage) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
      }
    });

    return voiceAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (error, _) => IconButton(
        tooltip: 'تعذّر الاتصال بالمكالمة الصوتية',
        icon: Icon(
          Icons.error_outline,
          color: Theme.of(context).colorScheme.error,
        ),
        onPressed: null,
      ),
      data: (voiceState) {
        final connected =
            voiceState.connectionStatus == VoiceConnectionStatus.connected;
        final reconnecting =
            voiceState.connectionStatus == VoiceConnectionStatus.reconnecting;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (reconnecting)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            IconButton(
              tooltip: voiceState.speakerEnabled
                  ? 'وقّف السماع'
                  : 'اسمع الآخرين',
              icon: Icon(
                voiceState.speakerEnabled ? Icons.volume_up : Icons.volume_off,
              ),
              onPressed: connected ? controller.toggleSpeaker : null,
            ),
            IconButton(
              tooltip: voiceState.micEnabled
                  ? 'سكّر الميكروفون'
                  : 'فتح الميكروفون',
              icon: Icon(voiceState.micEnabled ? Icons.mic : Icons.mic_off),
              onPressed: connected ? controller.toggleMic : null,
            ),
          ],
        );
      },
    );
  }
}
