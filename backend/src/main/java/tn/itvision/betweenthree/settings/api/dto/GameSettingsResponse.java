package tn.itvision.betweenthree.settings.api.dto;

import tn.itvision.betweenthree.settings.domain.GameSettings;

public record GameSettingsResponse(
    int powerCardsPerPlayer
) {
    public static GameSettingsResponse from(GameSettings settings) {
        return new GameSettingsResponse(settings.getPowerCardsPerPlayer());
    }
}
