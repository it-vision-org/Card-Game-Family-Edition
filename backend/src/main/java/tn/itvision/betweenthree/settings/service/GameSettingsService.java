package tn.itvision.betweenthree.settings.service;

import java.time.Instant;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import tn.itvision.betweenthree.common.api.ApiException;
import tn.itvision.betweenthree.identity.domain.AppUser;
import tn.itvision.betweenthree.settings.domain.GameSettings;
import tn.itvision.betweenthree.settings.repository.GameSettingsRepository;

@Service
public class GameSettingsService {

    private final GameSettingsRepository repository;

    public GameSettingsService(GameSettingsRepository repository) {
        this.repository = repository;
    }

    @Transactional(readOnly = true)
    public GameSettings getSettings() {
        return repository.findById(GameSettings.SINGLETON_ID)
            .orElseThrow(() -> new IllegalStateException("game_settings singleton row is missing"));
    }

    @Transactional
    public GameSettings updatePowerCardsPerPlayer(int value, AppUser admin) {
        if (value < 1 || value > 50) {
            throw ApiException.badRequest("INVALID_POWER_CARDS_COUNT", "Power cards per player must be between 1 and 50");
        }

        GameSettings settings = getSettings();
        settings.setPowerCardsPerPlayer((short) value);
        settings.setUpdatedAt(Instant.now());
        settings.setUpdatedBy(admin);
        return repository.save(settings);
    }
}
