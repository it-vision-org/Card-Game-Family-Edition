class PowerCardAssignment {
  const PowerCardAssignment({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.used,
    required this.targetParticipantId,
  });

  factory PowerCardAssignment.fromJson(Map<String, dynamic> json) {
    return PowerCardAssignment(
      id: json['id'] as String,
      code: json['code'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      used: json['used'] as bool,
      targetParticipantId: json['targetParticipantId'] as String?,
    );
  }

  final String id;
  final String code;
  final String title;
  final String description;
  final bool used;
  final String? targetParticipantId;
}

class Participant {
  const Participant({
    required this.id,
    required this.userId,
    required this.publicId,
    required this.displayName,
    required this.turnPosition,
    required this.score,
    required this.currentTurn,
    required this.joinedViaCode,
    required this.powerCards,
  });

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      id: json['id'] as String,
      userId: json['userId'] as String,
      publicId: json['publicId'] as String,
      displayName: json['displayName'] as String,
      turnPosition: json['turnPosition'] as int,
      score: json['score'] as int,
      currentTurn: json['currentTurn'] as bool,
      joinedViaCode: json['joinedViaCode'] as bool,
      powerCards: (json['powerCards'] as List<dynamic>)
          .map((e) => PowerCardAssignment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final String id;
  final String userId;
  final String publicId;
  final String displayName;
  final int turnPosition;
  final int score;
  final bool currentTurn;

  /// True only for a player who entered the session code themselves on their
  /// own login (real multi-device play), as opposed to being added via the
  /// "same phone" quick-add flow. See [SessionState.isMultiDevice].
  final bool joinedViaCode;
  final List<PowerCardAssignment> powerCards;
}

class CurrentCard {
  const CurrentCard({
    required this.sessionCardId,
    required this.cardId,
    required this.type,
    required this.categoryCode,
    required this.title,
    required this.text,
    required this.instructions,
    required this.answerMode,
    required this.timerSeconds,
    required this.skippable,
    required this.supportsScoring,
    required this.activeParticipantId,
  });

  factory CurrentCard.fromJson(Map<String, dynamic> json) {
    return CurrentCard(
      sessionCardId: json['sessionCardId'] as String,
      cardId: json['cardId'] as String,
      type: json['type'] as String,
      categoryCode: json['categoryCode'] as String?,
      title: json['title'] as String?,
      text: json['text'] as String?,
      instructions: json['instructions'] as String?,
      answerMode: json['answerMode'] as String?,
      timerSeconds: json['timerSeconds'] as int?,
      skippable: json['skippable'] as bool,
      supportsScoring: json['supportsScoring'] as bool,
      activeParticipantId: json['activeParticipantId'] as String?,
    );
  }

  final String sessionCardId;
  final String cardId;
  final String type;
  final String? categoryCode;
  final String? title;
  final String? text;
  final String? instructions;
  final String? answerMode;
  final int? timerSeconds;
  final bool skippable;
  final bool supportsScoring;
  final String? activeParticipantId;
}

class SessionState {
  const SessionState({
    required this.id,
    required this.sessionCode,
    required this.status,
    required this.gameMode,
    required this.categoryCode,
    required this.scoringEnabled,
    required this.requestedCardCount,
    required this.completedCardCount,
    required this.participants,
    required this.currentCard,
    required this.startedAt,
    required this.pausedAt,
    required this.completedAt,
    required this.version,
  });

  factory SessionState.fromJson(Map<String, dynamic> json) {
    return SessionState(
      id: json['id'] as String,
      sessionCode: json['sessionCode'] as String,
      status: json['status'] as String,
      gameMode: json['gameMode'] as String,
      categoryCode: json['categoryCode'] as String?,
      scoringEnabled: json['scoringEnabled'] as bool,
      requestedCardCount: json['requestedCardCount'] as int,
      completedCardCount: json['completedCardCount'] as int,
      participants: (json['participants'] as List<dynamic>)
          .map((e) => Participant.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentCard: json['currentCard'] == null
          ? null
          : CurrentCard.fromJson(json['currentCard'] as Map<String, dynamic>),
      startedAt: json['startedAt'] as String?,
      pausedAt: json['pausedAt'] as String?,
      completedAt: json['completedAt'] as String?,
      version: json['version'] as int,
    );
  }

  final String id;
  final String sessionCode;
  final String status;
  final String gameMode;
  final String? categoryCode;
  final bool scoringEnabled;
  final int requestedCardCount;
  final int completedCardCount;
  final List<Participant> participants;
  final CurrentCard? currentCard;
  final String? startedAt;
  final String? pausedAt;
  final String? completedAt;
  final int version;

  /// True only when at least one participant actually joined by entering the
  /// session code on their own login — i.e. this is genuinely being played
  /// across separate devices, not one phone passed around the table.
  bool get isMultiDevice => participants.any((p) => p.joinedViaCode);
}

class SessionSummary {
  const SessionSummary({
    required this.id,
    required this.sessionCode,
    required this.status,
    required this.gameMode,
    required this.requestedCardCount,
    required this.completedCardCount,
    required this.startedAt,
    required this.completedAt,
  });

  factory SessionSummary.fromJson(Map<String, dynamic> json) {
    return SessionSummary(
      id: json['id'] as String,
      sessionCode: json['sessionCode'] as String,
      status: json['status'] as String,
      gameMode: json['gameMode'] as String,
      requestedCardCount: json['requestedCardCount'] as int,
      completedCardCount: json['completedCardCount'] as int,
      startedAt: json['startedAt'] as String?,
      completedAt: json['completedAt'] as String?,
    );
  }

  final String id;
  final String sessionCode;
  final String status;
  final String gameMode;
  final int requestedCardCount;
  final int completedCardCount;
  final String? startedAt;
  final String? completedAt;
}
