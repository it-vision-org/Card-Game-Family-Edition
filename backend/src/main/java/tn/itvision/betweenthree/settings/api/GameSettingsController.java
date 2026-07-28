package tn.itvision.betweenthree.settings.api;

import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import jakarta.validation.Valid;
import tn.itvision.betweenthree.common.security.CurrentUserProvider;
import tn.itvision.betweenthree.identity.domain.AppUser;
import tn.itvision.betweenthree.settings.api.dto.GameSettingsResponse;
import tn.itvision.betweenthree.settings.api.dto.UpdateGameSettingsRequest;
import tn.itvision.betweenthree.settings.service.GameSettingsService;

@RestController
public class GameSettingsController {

    private final GameSettingsService gameSettingsService;
    private final CurrentUserProvider currentUserProvider;

    public GameSettingsController(GameSettingsService gameSettingsService, CurrentUserProvider currentUserProvider) {
        this.gameSettingsService = gameSettingsService;
        this.currentUserProvider = currentUserProvider;
    }

    @GetMapping("/api/v1/game-settings")
    public GameSettingsResponse getSettings() {
        return GameSettingsResponse.from(gameSettingsService.getSettings());
    }

    @PatchMapping("/api/v1/admin/game-settings")
    @PreAuthorize("hasRole('ADMIN')")
    public GameSettingsResponse updateSettings(
        @Valid @RequestBody UpdateGameSettingsRequest request,
        @AuthenticationPrincipal Jwt jwt
    ) {
        AppUser admin = currentUserProvider.require(jwt);
        return GameSettingsResponse.from(
            gameSettingsService.updatePowerCardsPerPlayer(request.powerCardsPerPlayer(), admin)
        );
    }
}
