package tn.itvision.betweenthree.content.api;

import java.util.UUID;

import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import tn.itvision.betweenthree.common.api.ApiException;
import tn.itvision.betweenthree.content.api.dto.CardResponse;
import tn.itvision.betweenthree.content.api.dto.UpdateCardRequest;
import tn.itvision.betweenthree.content.domain.Card;
import tn.itvision.betweenthree.content.repository.CardRepository;
import tn.itvision.betweenthree.content.repository.CardTranslationRepository;

@RestController
@RequestMapping("/api/v1/admin/cards")
@PreAuthorize("hasRole('ADMIN')")
public class AdminCardController {

    private static final String DEFAULT_LANGUAGE = "ar-TN";

    private final CardRepository cardRepository;
    private final CardTranslationRepository translationRepository;

    public AdminCardController(CardRepository cardRepository, CardTranslationRepository translationRepository) {
        this.cardRepository = cardRepository;
        this.translationRepository = translationRepository;
    }

    @PatchMapping("/{cardId}")
    public CardResponse updateCard(@PathVariable UUID cardId, @RequestBody UpdateCardRequest request) {
        Card card = cardRepository.findById(cardId)
            .orElseThrow(() -> ApiException.notFound("CARD_NOT_FOUND", "Card not found"));

        if (request.best() != null) {
            card.setBest(request.best());
        }
        if (request.active() != null) {
            card.setActive(request.active());
        }
        card = cardRepository.save(card);

        var translation = translationRepository.findByCardIdAndLanguageCode(card.getId(), DEFAULT_LANGUAGE)
            .orElse(null);
        return CardResponse.from(card, translation);
    }
}
