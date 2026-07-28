import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/environment.dart';

class SessionSocketEvent {
  const SessionSocketEvent({required this.type, required this.payload});

  factory SessionSocketEvent.fromJson(Map<String, dynamic> json) {
    return SessionSocketEvent(
      type: json['type'] as String,
      payload: json['payload'] as Map<String, dynamic>,
    );
  }

  final String type;
  final Map<String, dynamic> payload;
}

/// One live stream per session code, broadcasting the fresh `SessionState`
/// (as JSON) after every state-changing action on the backend — see
/// `SessionSocketHandler` server-side. Riverpod tears the socket down
/// automatically once the last listener (the active-game screen) goes away.
final sessionSocketProvider =
    StreamProvider.autoDispose.family<SessionSocketEvent, String>((ref, sessionCode) {
  final uri = Uri.parse('${Environment.websocketBaseUrl}/sessions/$sessionCode');
  final channel = WebSocketChannel.connect(uri);

  ref.onDispose(() {
    channel.sink.close();
  });

  return channel.stream.map((raw) {
    final decoded = jsonDecode(raw as String) as Map<String, dynamic>;
    return SessionSocketEvent.fromJson(decoded);
  });
});
