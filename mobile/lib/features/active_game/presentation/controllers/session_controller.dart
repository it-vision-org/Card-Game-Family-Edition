import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/realtime/session_socket_client.dart';
import '../../data/models/session_state.dart';
import '../../data/repositories/session_repository.dart';

part 'session_controller.g.dart';

/// Holds the live state for one session: seeded from a REST fetch, then kept
/// in sync by listening to the session's WebSocket channel (see
/// `SessionSocketHandler` server-side, which re-broadcasts the full state
/// after every mutation any participant makes, on any device).
@riverpod
class SessionController extends _$SessionController {
  @override
  FutureOr<SessionState> build(String sessionId) async {
    final initial = await ref.watch(sessionRepositoryProvider).getState(sessionId);

    ref.listen(sessionSocketProvider(initial.sessionCode), (previous, next) {
      next.whenData((event) {
        if (event.type == 'SESSION_UPDATED') {
          _applyIfNewer(SessionState.fromJson(event.payload));
        }
      });
    });

    return initial;
  }

  /// The HTTP response for a mutation and the WebSocket echo of that same
  /// mutation race independently; without this guard, a slightly-delayed
  /// broadcast for an *older* change can arrive after a newer HTTP response
  /// already landed and silently revert the screen (e.g. a power-card pick
  /// "not saving" until another action happens to re-sync it). `version` is
  /// the session's JPA optimistic-lock counter, which only ever increases.
  void _applyIfNewer(SessionState candidate) {
    final current = state.value;
    if (current != null && candidate.version < current.version) {
      return;
    }
    state = AsyncData(candidate);
  }

  Future<void> refresh() => _mutate((repo) => repo.getState(sessionId));

  Future<void> addParticipant(String userPublicId) {
    return _mutate((repo) => repo.addParticipant(sessionId, userPublicId));
  }

  Future<void> choosePowerCards(String participantId, List<String> powerCardDefinitionIds) {
    return _mutate((repo) => repo.choosePowerCards(sessionId, participantId, powerCardDefinitionIds));
  }

  Future<void> start() => _mutate((repo) => repo.start(sessionId));

  Future<void> completeCurrentCard(String sessionCardId) {
    return _mutate((repo) => repo.completeCard(sessionId, sessionCardId));
  }

  Future<void> skipCurrentCard(String sessionCardId) {
    return _mutate((repo) => repo.skipCard(sessionId, sessionCardId));
  }

  Future<void> usePowerCard(String assignmentId, {String? targetParticipantId}) {
    return _mutate(
      (repo) => repo.usePowerCard(sessionId, assignmentId, targetParticipantId: targetParticipantId),
    );
  }

  Future<void> awardScore({
    required String participantId,
    required int points,
    required String reasonCode,
    String? note,
  }) {
    return _mutate(
      (repo) => repo.awardScore(
        sessionId,
        participantId: participantId,
        points: points,
        reasonCode: reasonCode,
        note: note,
      ),
    );
  }

  Future<void> pause() => _mutate((repo) => repo.pause(sessionId));

  Future<void> resume() => _mutate((repo) => repo.resume(sessionId));

  Future<void> cancel() => _mutate((repo) => repo.cancel(sessionId));

  /// Runs a mutating call and, on success, updates [state]. On failure the
  /// exception propagates to the caller (a page's try/catch) so a transient
  /// error (e.g. a stale-card 409) can show a snackbar without blanking the
  /// screen the way replacing [state] with [AsyncError] would.
  Future<void> _mutate(Future<SessionState> Function(SessionRepository repo) action) async {
    final updated = await action(ref.read(sessionRepositoryProvider));
    _applyIfNewer(updated);
  }
}
