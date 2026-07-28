package tn.itvision.betweenthree.sessions.api.dto;

import java.time.Instant;
import java.util.UUID;

public record SessionSummaryResponse(
    UUID id,
    String sessionCode,
    String status,
    String gameMode,
    int requestedCardCount,
    int completedCardCount,
    Instant startedAt,
    Instant completedAt
) {
}
