package tn.itvision.betweenthree.content.domain;

import java.time.Instant;
import java.util.UUID;

import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

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
@Table(name = "card_translations")
@Getter
@Setter
@NoArgsConstructor
public class CardTranslation {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(optional = false)
    @JoinColumn(name = "card_id", nullable = false)
    private Card card;

    @Column(name = "language_code", nullable = false, length = 10)
    private String languageCode;

    @Column(name = "title", length = 200)
    private String title;

    @Column(name = "text", nullable = false, columnDefinition = "text")
    private String text;

    @Column(name = "instructions", columnDefinition = "text")
    private String instructions;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    public CardTranslation(Card card, String languageCode, String title, String text, String instructions) {
        this.card = card;
        this.languageCode = languageCode;
        this.title = title;
        this.text = text;
        this.instructions = instructions;
    }
}
