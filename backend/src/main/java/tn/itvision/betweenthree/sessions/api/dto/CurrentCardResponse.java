package tn.itvision.betweenthree.sessions.api.dto;

import java.util.UUID;

public record CurrentCardResponse(
    UUID sessionCardId,
    UUID cardId,
    String type,
    String categoryCode,
    String title,
    String text,
    String instructions,
    String answerMode,
    Integer timerSeconds,
    boolean skippable,
    boolean supportsScoring,
    UUID activeParticipantId
) {
}
