package tn.itvision.betweenthree.sessions.domain;

import java.time.Instant;
import java.util.UUID;

import org.hibernate.annotations.CreationTimestamp;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import tn.itvision.betweenthree.identity.domain.AppUser;

@Entity
@Table(name = "session_participants")
@Getter
@Setter
@NoArgsConstructor
public class SessionParticipant {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(optional = false)
    @JoinColumn(name = "session_id", nullable = false)
    private GameSession session;

    @ManyToOne(optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private AppUser user;

    @Column(name = "turn_position", nullable = false)
    private int turnPosition;

    @Column(name = "score", nullable = false)
    private int score;

    @CreationTimestamp
    @Column(name = "joined_at", nullable = false, updatable = false)
    private Instant joinedAt;

    /**
     * True only when this player entered the session code themselves, on
     * their own login — i.e. real multi-device play. False for the session
     * creator and for anyone added via the "same phone" quick-add flow.
     * {@code SessionService.isMultiDevice} checks whether any participant
     * has this set.
     */
    @Column(name = "joined_via_code", nullable = false)
    private boolean joinedViaCode;

    public SessionParticipant(GameSession session, AppUser user, int turnPosition) {
        this.session = session;
        this.user = user;
        this.turnPosition = turnPosition;
    }
}
