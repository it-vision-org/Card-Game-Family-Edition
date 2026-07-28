package tn.itvision.betweenthree.content.api.dto;

import java.util.UUID;

import tn.itvision.betweenthree.content.domain.CardCategory;

public record CategoryResponse(
    UUID id,
    String code,
    int sortOrder
) {
    public static CategoryResponse from(CardCategory category) {
        return new CategoryResponse(category.getId(), category.getCode(), category.getSortOrder());
    }
}
