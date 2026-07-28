package tn.itvision.betweenthree.sessions.api.dto;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

public record SessionStateResponse(
    UUID id,
    String sessionCode,
    String status,
    String gameMode,
    String categoryCode,
    boolean scoringEnabled,
    int requestedCardCount,
    int completedCardCount,
    List<ParticipantResponse> participants,
    CurrentCardResponse currentCard,
    Instant startedAt,
    Instant pausedAt,
    Instant completedAt,
    long version
) {
}
