class GameSettings {
  const GameSettings({required this.powerCardsPerPlayer});

  factory GameSettings.fromJson(Map<String, dynamic> json) {
    return GameSettings(
      powerCardsPerPlayer: json['powerCardsPerPlayer'] as int,
    );
  }

  final int powerCardsPerPlayer;
}
