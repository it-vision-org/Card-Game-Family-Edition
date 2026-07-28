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
import tn.itvision.betweenthree.content.domain.Card;
import tn.itvision.betweenthree.groups.domain.GameGroup;

@Entity
@Table(name = "card_trash")
@Getter
@Setter
@NoArgsConstructor
public class CardTrash {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(optional = false)
    @JoinColumn(name = "group_id", nullable = false)
    private GameGroup group;

    @ManyToOne(optional = false)
    @JoinColumn(name = "card_id", nullable = false)
    private Card card;

    @ManyToOne(optional = false)
    @JoinColumn(name = "source_session_id", nullable = false)
    private GameSession sourceSession;

    @CreationTimestamp
    @Column(name = "trashed_at", nullable = false, updatable = false)
    private Instant trashedAt;

    public CardTrash(GameGroup group, Card card, GameSession sourceSession) {
        this.group = group;
        this.card = card;
        this.sourceSession = sourceSession;
    }
}
