package tn.itvision.betweenthree.content.domain;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.annotations.UpdateTimestamp;
import org.hibernate.type.SqlTypes;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "cards")
@Getter
@Setter
@NoArgsConstructor
public class Card {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "external_key", nullable = false, unique = true, length = 100)
    private String externalKey;

    @ManyToOne
    @JoinColumn(name = "category_id")
    private CardCategory category;

    @Enumerated(EnumType.STRING)
    @JdbcTypeCode(SqlTypes.NAMED_ENUM)
    @Column(name = "card_type", nullable = false)
    private CardType cardType;

    /**
     * Which seeded player(s) (by {@code app_users.public_id}) this card may be
     * drawn for — checked against whoever's turn it is when a session's card
     * sequence is built in {@code SessionService.buildEligibleSequence}.
     */
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "eligible_player_public_ids", nullable = false)
    private List<String> eligiblePlayerPublicIds = new ArrayList<>();

    /**
     * Free-form hint for how the client should present the answer flow (e.g.
     * {@code ALL_PLAYERS_SEQUENTIALLY} drives the repeat-timer + "التالي"
     * UX); {@code null} means the default single-active-player display.
     */
    @Column(name = "answer_mode", length = 50)
    private String answerMode;

    @Column(name = "is_best", nullable = false)
    private boolean best;

    @Column(name = "is_active", nullable = false)
    private boolean active = true;

    @Column(name = "is_skippable", nullable = false)
    private boolean skippable = true;

    @Column(name = "supports_scoring", nullable = false)
    private boolean supportsScoring;

    @Column(name = "sensitivity_level", nullable = false)
    private short sensitivityLevel;

    @Column(name = "emotional_depth", nullable = false)
    private short emotionalDepth;

    @Column(name = "minimum_players", nullable = false)
    private short minimumPlayers = 2;

    @Column(name = "maximum_players")
    private Short maximumPlayers;

    @Column(name = "requires_timer", nullable = false)
    private boolean requiresTimer;

    @Column(name = "timer_seconds")
    private Integer timerSeconds;

    @Column(name = "selection_weight", nullable = false)
    private int selectionWeight = 100;

    /**
     * Set only for player-authored cards created from the "Cards" screen;
     * {@code null} for the original curated/seeded catalog. Used to scope
     * the my-cards CRUD endpoints so a player can only manage their own.
     */
    @Column(name = "created_by_user_id")
    private UUID createdByUserId;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @Column(name = "deleted_at")
    private Instant deletedAt;
}
