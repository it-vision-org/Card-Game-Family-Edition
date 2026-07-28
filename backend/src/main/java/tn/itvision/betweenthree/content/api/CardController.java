package tn.itvision.betweenthree.content.api;

import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import tn.itvision.betweenthree.content.api.dto.CardResponse;
import tn.itvision.betweenthree.content.api.dto.CategoryResponse;
import tn.itvision.betweenthree.content.domain.Card;
import tn.itvision.betweenthree.content.domain.CardTranslation;
import tn.itvision.betweenthree.content.domain.CardType;
import tn.itvision.betweenthree.content.repository.CardCategoryRepository;
import tn.itvision.betweenthree.content.repository.CardRepository;
import tn.itvision.betweenthree.content.repository.CardTranslationRepository;

@RestController
@RequestMapping("/api/v1/cards")
public class CardController {

    private static final String DEFAULT_LANGUAGE = "ar-TN";

    private final CardRepository cardRepository;
    private final CardCategoryRepository categoryRepository;
    private final CardTranslationRepository translationRepository;

    public CardController(
        CardRepository cardRepository,
        CardCategoryRepository categoryRepository,
        CardTranslationRepository translationRepository
    ) {
        this.cardRepository = cardRepository;
        this.categoryRepository = categoryRepository;
        this.translationRepository = translationRepository;
    }

    @GetMapping("/categories")
    public List<CategoryResponse> listCategories() {
        return categoryRepository.findAllByOrderBySortOrderAsc().stream()
            .map(CategoryResponse::from)
            .toList();
    }

    @GetMapping
    public List<CardResponse> listCards(
        @RequestParam(required = false) String categoryCode,
        @RequestParam(required = false) CardType type,
        @RequestParam(defaultValue = "false") boolean bestOnly
    ) {
        List<Card> cards = cardRepository.findEligibleCards(List.of(), type, categoryCode, bestOnly);
        List<UUID> cardIds = cards.stream().map(Card::getId).toList();

        Map<UUID, CardTranslation> translationsByCard = translationRepository.findByCardIdIn(cardIds).stream()
            .filter(t -> DEFAULT_LANGUAGE.equals(t.getLanguageCode()))
            .collect(java.util.stream.Collectors.toMap(t -> t.getCard().getId(), Function.identity()));

        return cards.stream()
            .map(card -> CardResponse.from(card, translationsByCard.get(card.getId())))
            .toList();
    }
}
