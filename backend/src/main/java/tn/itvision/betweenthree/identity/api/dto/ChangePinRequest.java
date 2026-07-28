package tn.itvision.betweenthree.identity.api.dto;

import jakarta.validation.constraints.NotBlank;

public record ChangePinRequest(
    @NotBlank String currentPin,
    @NotBlank String newPin
) {
}
