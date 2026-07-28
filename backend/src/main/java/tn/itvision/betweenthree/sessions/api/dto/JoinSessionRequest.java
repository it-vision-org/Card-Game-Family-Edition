package tn.itvision.betweenthree.sessions.api.dto;

import jakarta.validation.constraints.NotBlank;

public record JoinSessionRequest(
    @NotBlank String sessionCode
) {
}
