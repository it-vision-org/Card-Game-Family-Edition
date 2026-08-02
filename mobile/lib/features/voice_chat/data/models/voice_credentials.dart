class VoiceCredentials {
  const VoiceCredentials({
    required this.url,
    required this.token,
    required this.roomName,
  });

  factory VoiceCredentials.fromJson(Map<String, dynamic> json) {
    return VoiceCredentials(
      url: json['url'] as String,
      token: json['token'] as String,
      roomName: json['roomName'] as String,
    );
  }

  final String url;
  final String token;
  final String roomName;
}
