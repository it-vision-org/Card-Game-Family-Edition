package tn.itvision.betweenthree.content.api.dto;

import java.util.List;
import java.util.UUID;

import tn.itvision.betweenthree.content.domain.Card;
import tn.itvision.betweenthree.content.domain.CardTranslation;

public record CardResponse(
    UUID id,
    String externalKey,
    String type,
    String categoryCode,
    boolean best,
    boolean active,
    boolean skippable,
    boolean supportsScoring,
    int sensitivityLevel,
    int emotionalDepth,
    Integer timerSeconds,
    List<String> eligiblePlayerPublicIds,
    String answerMode,
    String title,
    String text,
    String instructions
) {
    public static CardResponse from(Card card, CardTranslation translation) {
        return new CardResponse(
            card.getId(),
            card.getExternalKey(),
            card.getCardType().name(),
            card.getCategory() != null ? card.getCategory().getCode() : null,
            card.isBest(),
            card.isActive(),
            card.isSkippable(),
            card.isSupportsScoring(),
            card.getSensitivityLevel(),
            card.getEmotionalDepth(),
            card.getTimerSeconds(),
            card.getEligiblePlayerPublicIds(),
            card.getAnswerMode(),
            translation != null ? translation.getTitle() : null,
            translation != null ? translation.getText() : null,
            translation != null ? translation.getInstructions() : null
        );
    }
}
