package tn.itvision.betweenthree.sessions.domain;

import java.time.Instant;
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
import jakarta.persistence.Version;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import tn.itvision.betweenthree.groups.domain.GameGroup;
import tn.itvision.betweenthree.identity.domain.AppUser;

@Entity
@Table(name = "game_sessions")
@Getter
@Setter
@NoArgsConstructor
public class GameSession {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne
    @JoinColumn(name = "group_id")
    private GameGroup group;

    @ManyToOne(optional = false)
    @JoinColumn(name = "created_by", nullable = false)
    private AppUser createdBy;

    @Column(name = "session_code", nullable = false, unique = true, length = 12)
    private String sessionCode;

    @Enumerated(EnumType.STRING)
    @JdbcTypeCode(SqlTypes.NAMED_ENUM)
    @Column(name = "status", nullable = false)
    private SessionStatus status = SessionStatus.WAITING_FOR_PLAYERS;

    @Enumerated(EnumType.STRING)
    @JdbcTypeCode(SqlTypes.NAMED_ENUM)
    @Column(name = "game_mode", nullable = false)
    private GameMode gameMode;

    @Column(name = "scoring_enabled", nullable = false)
    private boolean scoringEnabled;

    @Column(name = "category_code", length = 80)
    private String categoryCode;

    @Column(name = "requested_card_count", nullable = false)
    private int requestedCardCount;

    @Column(name = "completed_card_count", nullable = false)
    private int completedCardCount;

    @Column(name = "current_turn_position")
    private Integer currentTurnPosition;

    @Column(name = "random_seed", nullable = false)
    private long randomSeed;

    @Version
    @Column(name = "version", nullable = false)
    private long version;

    @Column(name = "started_at")
    private Instant startedAt;

    @Column(name = "paused_at")
    private Instant pausedAt;

    @Column(name = "completed_at")
    private Instant completedAt;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;
}
