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

@Entity
@Table(name = "score_events")
@Getter
@Setter
@NoArgsConstructor
public class ScoreEvent {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(optional = false)
    @JoinColumn(name = "session_id", nullable = false)
    private GameSession session;

    @ManyToOne
    @JoinColumn(name = "session_card_id")
    private SessionCard sessionCard;

    @ManyToOne(optional = false)
    @JoinColumn(name = "participant_id", nullable = false)
    private SessionParticipant participant;

    @Column(nullable = false)
    private int points;

    @Column(name = "reason_code", nullable = false, length = 50)
    private String reasonCode;

    @Column(length = 255)
    private String note;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    public ScoreEvent(GameSession session, SessionCard sessionCard, SessionParticipant participant, int points, String reasonCode, String note) {
        this.session = session;
        this.sessionCard = sessionCard;
        this.participant = participant;
        this.points = points;
        this.reasonCode = reasonCode;
        this.note = note;
    }
}
