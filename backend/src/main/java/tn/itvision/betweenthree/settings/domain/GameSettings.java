package tn.itvision.betweenthree.settings.domain;

import java.time.Instant;
import java.util.UUID;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import tn.itvision.betweenthree.identity.domain.AppUser;

/**
 * Single-row game-wide configuration (see {@link #SINGLETON_ID}), editable at
 * runtime by an admin instead of a static {@code application.yaml} property —
 * so the power-cards-per-player count can change without a redeploy.
 */
@Entity
@Table(name = "game_settings")
@Getter
@Setter
@NoArgsConstructor
public class GameSettings {

    public static final UUID SINGLETON_ID = UUID.fromString("00000000-0000-0000-0000-000000000001");

    @Id
    private UUID id;

    @Column(name = "power_cards_per_player", nullable = false)
    private short powerCardsPerPlayer;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @ManyToOne
    @JoinColumn(name = "updated_by")
    private AppUser updatedBy;
}
