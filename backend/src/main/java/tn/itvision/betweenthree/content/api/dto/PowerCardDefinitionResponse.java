package tn.itvision.betweenthree.content.api.dto;

import java.util.UUID;

import tn.itvision.betweenthree.content.domain.PowerCardDefinition;

public record PowerCardDefinitionResponse(
    UUID id,
    String code,
    String title,
    String description
) {
    public static PowerCardDefinitionResponse from(PowerCardDefinition definition) {
        return new PowerCardDefinitionResponse(
            definition.getId(),
            definition.getCode(),
            definition.getTitle(),
            definition.getDescription()
        );
    }
}
