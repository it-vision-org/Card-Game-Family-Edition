package tn.itvision.betweenthree.sessions.api.dto;

import java.util.List;
import java.util.UUID;

import jakarta.validation.constraints.NotEmpty;

public record ChoosePowerCardsRequest(
    @NotEmpty List<UUID> powerCardDefinitionIds
) {
}
