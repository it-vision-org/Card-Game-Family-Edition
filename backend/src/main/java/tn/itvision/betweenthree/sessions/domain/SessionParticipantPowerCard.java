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
import tn.itvision.betweenthree.content.domain.PowerCardDefinition;

@Entity
@Table(name = "session_participant_power_cards")
@Getter
@Setter
@NoArgsConstructor
public class SessionParticipantPowerCard {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(optional = false)
    @JoinColumn(name = "session_id", nullable = false)
    private GameSession session;

    @ManyToOne(optional = false)
    @JoinColumn(name = "participant_id", nullable = false)
    private SessionParticipant participant;

    @ManyToOne(optional = false)
    @JoinColumn(name = "power_card_definition_id", nullable = false)
    private PowerCardDefinition powerCardDefinition;

    @ManyToOne
    @JoinColumn(name = "target_participant_id")
    private SessionParticipant targetParticipant;

    @ManyToOne
    @JoinColumn(name = "used_on_session_card_id")
    private SessionCard usedOnSessionCard;

    @CreationTimestamp
    @Column(name = "granted_at", nullable = false, updatable = false)
    private Instant grantedAt;

    @Column(name = "used_at")
    private Instant usedAt;

    public SessionParticipantPowerCard(GameSession session, SessionParticipant participant, PowerCardDefinition definition) {
        this.session = session;
        this.participant = participant;
        this.powerCardDefinition = definition;
    }

    public boolean isUsed() {
        return usedAt != null;
    }
}
