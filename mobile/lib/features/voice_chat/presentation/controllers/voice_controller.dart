import 'dart:async';

import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../active_game/presentation/controllers/session_controller.dart';
import '../../data/repositories/voice_repository.dart';

part 'voice_controller.g.dart';

enum VoiceConnectionStatus {
  connecting,
  connected,
  reconnecting,
  disconnected,
  failed,
}

class VoiceChatState {
  const VoiceChatState({
    required this.connectionStatus,
    required this.micEnabled,
    required this.speakerEnabled,
    this.micPermissionDenied = false,
    this.errorMessage,
  });

  final VoiceConnectionStatus connectionStatus;

  /// Whether *this* player is publishing their microphone.
  final bool micEnabled;

  /// Whether *this* player can currently hear other participants. Purely
  /// local: it never affects what other players hear, and applies both to
  /// participants already in the room and any who join afterwards.
  final bool speakerEnabled;

  final bool micPermissionDenied;
  final String? errorMessage;

  VoiceChatState copyWith({
    VoiceConnectionStatus? connectionStatus,
    bool? micEnabled,
    bool? speakerEnabled,
    bool? micPermissionDenied,
    String? errorMessage,
  }) {
    return VoiceChatState(
      connectionStatus: connectionStatus ?? this.connectionStatus,
      micEnabled: micEnabled ?? this.micEnabled,
      speakerEnabled: speakerEnabled ?? this.speakerEnabled,
      micPermissionDenied: micPermissionDenied ?? this.micPermissionDenied,
      errorMessage: errorMessage,
    );
  }
}

/// Owns the LiveKit [lk.Room] connection for one game session's voice chat.
/// Kept alive for as long as any screen for this [sessionId] is on screen
/// (the lobby and active-game pages both watch this same family-keyed
/// provider), so the room connection survives navigating between them, and
/// is torn down automatically once neither screen is showing (matching the
/// auto-dispose convention already used by [sessionControllerProvider] and
/// the session WebSocket).
///
/// Mic and speaker are independent local toggles, both off by default:
/// - Mic: publishes/unpublishes this device's microphone track. Permission
///   is requested only the first time it's turned on.
/// - Speaker: purely local — enables/disables *playback* of already- and
///   later-subscribed remote audio tracks. Never touches what this device
///   publishes, and never affects other participants.
@riverpod
class VoiceController extends _$VoiceController {
  lk.Room? _room;
  lk.EventsListener<lk.RoomEvent>? _listener;
  bool _disconnected = false;

  @override
  FutureOr<VoiceChatState> build(String sessionId) async {
    ref.listen(sessionControllerProvider(sessionId), (previous, next) {
      final status = next.value?.status;
      if (status == 'COMPLETED' || status == 'CANCELLED') {
        _disconnect();
      }
    });
    ref.onDispose(_disconnect);

    final credentials = await ref
        .read(voiceRepositoryProvider)
        .fetchToken(sessionId);

    final room = lk.Room();
    _room = room;

    final listener = room.createListener();
    _listener = listener;
    listener
      ..on<lk.RoomReconnectingEvent>(
        (_) => _updateStatus(VoiceConnectionStatus.reconnecting),
      )
      ..on<lk.RoomReconnectedEvent>(
        (_) => _updateStatus(VoiceConnectionStatus.connected),
      )
      ..on<lk.RoomDisconnectedEvent>(
        (_) => _updateStatus(VoiceConnectionStatus.disconnected),
      )
      ..on<lk.ParticipantConnectedEvent>(
        (event) => _applySpeakerState(event.participant),
      )
      ..on<lk.TrackSubscribedEvent>(
        (event) => _applySpeakerStateToTrack(event.track),
      );

    try {
      await room.connect(credentials.url, credentials.token);
    } catch (_) {
      return const VoiceChatState(
        connectionStatus: VoiceConnectionStatus.failed,
        micEnabled: false,
        speakerEnabled: false,
        errorMessage: 'تعذّر الاتصال بالمكالمة الصوتية',
      );
    }

    return const VoiceChatState(
      connectionStatus: VoiceConnectionStatus.connected,
      micEnabled: false,
      speakerEnabled: false,
    );
  }

  Future<void> toggleMic() async {
    final current = state.value;
    final room = _room;
    if (current == null || room == null) return;

    final enabling = !current.micEnabled;

    if (enabling) {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        state = AsyncData(current.copyWith(micPermissionDenied: true));
        return;
      }
    }

    try {
      await room.localParticipant?.setMicrophoneEnabled(enabling);
      state = AsyncData(
        current.copyWith(micEnabled: enabling, micPermissionDenied: false),
      );
    } catch (_) {
      state = AsyncData(
        current.copyWith(errorMessage: 'تعذّر تفعيل الميكروفون'),
      );
    }
  }

  void toggleSpeaker() {
    final current = state.value;
    final room = _room;
    if (current == null || room == null) return;

    final enabling = !current.speakerEnabled;
    state = AsyncData(current.copyWith(speakerEnabled: enabling));

    for (final participant in room.remoteParticipants.values) {
      _applySpeakerState(participant, enabled: enabling);
    }
  }

  void _applySpeakerState(lk.RemoteParticipant participant, {bool? enabled}) {
    final resolved = enabled ?? state.value?.speakerEnabled ?? false;
    for (final publication in participant.audioTrackPublications) {
      final track = publication.track;
      if (track != null) {
        track.mediaStreamTrack.enabled = resolved;
      }
    }
  }

  void _applySpeakerStateToTrack(lk.Track track) {
    if (track is lk.RemoteAudioTrack) {
      track.mediaStreamTrack.enabled = state.value?.speakerEnabled ?? false;
    }
  }

  void _updateStatus(VoiceConnectionStatus status) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(connectionStatus: status));
  }

  Future<void> _disconnect() async {
    if (_disconnected) return;
    _disconnected = true;

    await _listener?.dispose();
    _listener = null;

    final room = _room;
    _room = null;
    if (room != null) {
      await room.disconnect();
      await room.dispose();
    }
  }
}
