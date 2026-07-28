package tn.itvision.betweenthree.sessions.api.dto;

import java.util.UUID;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record AwardScoreRequest(
    @NotNull UUID participantId,
    int points,
    @NotBlank String reasonCode,
    String note
) {
}
