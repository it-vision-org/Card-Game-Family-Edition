package tn.itvision.betweenthree.content.api.dto;

import java.util.List;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;

public record SaveMyCardRequest(
    @NotBlank String categoryCode,
    @NotBlank String text,
    @NotEmpty List<String> eligiblePlayerPublicIds,
    boolean best
) {
}
