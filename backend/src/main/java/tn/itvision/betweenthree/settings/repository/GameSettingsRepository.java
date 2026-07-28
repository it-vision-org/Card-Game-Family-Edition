package tn.itvision.betweenthree.settings.repository;

import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

import tn.itvision.betweenthree.settings.domain.GameSettings;

public interface GameSettingsRepository extends JpaRepository<GameSettings, UUID> {
}
