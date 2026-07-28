package tn.itvision.betweenthree.identity.api.dto;

import jakarta.validation.constraints.NotBlank;

public record LoginRequest(
    @NotBlank String publicId,
    @NotBlank String pin,
    String deviceInfo
) {
}
