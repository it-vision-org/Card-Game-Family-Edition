package tn.itvision.betweenthree.groups.api.dto;

import jakarta.validation.constraints.NotBlank;

public record DefineRelationshipRequest(
    @NotBlank String memberAPublicId,
    @NotBlank String memberBPublicId,
    @NotBlank String relationshipType
) {
}
