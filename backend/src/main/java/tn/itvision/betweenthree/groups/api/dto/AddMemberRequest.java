package tn.itvision.betweenthree.groups.api.dto;

import jakarta.validation.constraints.NotBlank;

public record AddMemberRequest(
    @NotBlank String publicId
) {
}
