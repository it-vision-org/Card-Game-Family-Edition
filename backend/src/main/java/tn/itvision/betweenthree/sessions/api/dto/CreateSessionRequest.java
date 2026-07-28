package tn.itvision.betweenthree.sessions.api.dto;

import java.util.UUID;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

public record CreateSessionRequest(
    @NotNull UUID groupId,
    @NotNull String gameMode,
    String categoryCode,
    @Min(1) int requestedCardCount,
    boolean scoringEnabled
) {
}
