package tn.itvision.betweenthree.content.api;

import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import jakarta.validation.Valid;
import tn.itvision.betweenthree.common.api.ApiException;
import tn.itvision.betweenthree.common.security.CurrentUserProvider;
import tn.itvision.betweenthree.content.api.dto.CardResponse;
import tn.itvision.betweenthree.content.api.dto.SaveMyCardRequest;
import tn.itvision.betweenthree.content.domain.Card;
import tn.itvision.betweenthree.content.domain.CardCategory;
import tn.itvision.betweenthree.content.domain.CardTranslation;
import tn.itvision.betweenthree.content.domain.CardType;
import tn.itvision.betweenthree.content.repository.CardCategoryRepository;
import tn.itvision.betweenthree.content.repository.CardRepository;
import tn.itvision.betweenthree.content.repository.CardTranslationRepository;
import tn.itvision.betweenthree.identity.domain.AppUser;

/**
 * Lets a player author their own questions (the "Cards" screen) rather than
 * only playing from the curated/seeded catalog. A player may only view,
 * edit or delete cards where {@code createdByUserId} matches their own id —
 * the curated catalog (createdByUserId == null) is never reachable here.
 */
@RestController
@RequestMapping("/api/v1/my-cards")
public class MyCardController {

    private static final String DEFAULT_LANGUAGE = "ar-TN";

    private final CardRepository cardRepository;
    private final CardCategoryRepository categoryRepository;
    private final CardTranslationRepository translationRepository;
    private final CurrentUserProvider currentUserProvider;

    public MyCardController(
        CardRepository cardRepository,
        CardCategoryRepository categoryRepository,
        CardTranslationRepository translationRepository,
        CurrentUserProvider currentUserProvider
    ) {
        this.cardRepository = cardRepository;
        this.categoryRepository = categoryRepository;
        this.translationRepository = translationRepository;
        this.currentUserProvider = currentUserProvider;
    }

    @GetMapping
    public List<CardResponse> listMyCards(@AuthenticationPrincipal Jwt jwt) {
        AppUser user = currentUserProvider.require(jwt);
        List<Card> cards = cardRepository.findByCreatedByUserId(user.getId());
        Map<UUID, CardTranslation> translationsByCardId = translationsFor(cards);

        return cards.stream()
            .map(card -> CardResponse.from(card, translationsByCardId.get(card.getId())))
            .toList();
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public CardResponse createCard(@AuthenticationPrincipal Jwt jwt, @Valid @RequestBody SaveMyCardRequest request) {
        AppUser user = currentUserProvider.require(jwt);
        CardCategory category = requireCategory(request.categoryCode());

        Card card = new Card();
        card.setExternalKey("USER_" + UUID.randomUUID());
        card.setCategory(category);
        card.setCardType(CardType.QUESTION);
        card.setEligiblePlayerPublicIds(request.eligiblePlayerPublicIds());
        card.setActive(true);
        card.setBest(request.best());
        card.setSkippable(true);
        card.setSupportsScoring(false);
        card.setSensitivityLevel((short) 1);
        card.setEmotionalDepth((short) 1);
        card.setCreatedByUserId(user.getId());
        card = cardRepository.save(card);

        CardTranslation translation = translationRepository.save(
            new CardTranslation(card, DEFAULT_LANGUAGE, null, request.text(), null)
        );

        return CardResponse.from(card, translation);
    }

    @PutMapping("/{cardId}")
    public CardResponse updateCard(
        @AuthenticationPrincipal Jwt jwt,
        @PathVariable UUID cardId,
        @Valid @RequestBody SaveMyCardRequest request
    ) {
        AppUser user = currentUserProvider.require(jwt);
        Card card = requireOwnedCard(cardId, user);
        CardCategory category = requireCategory(request.categoryCode());

        card.setCategory(category);
        card.setEligiblePlayerPublicIds(request.eligiblePlayerPublicIds());
        card.setBest(request.best());
        Card savedCard = cardRepository.save(card);

        CardTranslation translation = translationRepository
            .findByCardIdAndLanguageCode(savedCard.getId(), DEFAULT_LANGUAGE)
            .orElseGet(() -> new CardTranslation(savedCard, DEFAULT_LANGUAGE, null, request.text(), null));
        translation.setText(request.text());
        translation = translationRepository.save(translation);

        return CardResponse.from(savedCard, translation);
    }

    @DeleteMapping("/{cardId}")
    public ResponseEntity<Void> deleteCard(@AuthenticationPrincipal Jwt jwt, @PathVariable UUID cardId) {
        AppUser user = currentUserProvider.require(jwt);
        Card card = requireOwnedCard(cardId, user);

        translationRepository.deleteAll(translationRepository.findByCardIdIn(List.of(card.getId())));
        cardRepository.delete(card);

        return ResponseEntity.noContent().build();
    }

    private Card requireOwnedCard(UUID cardId, AppUser user) {
        Card card = cardRepository.findById(cardId)
            .orElseThrow(() -> ApiException.notFound("CARD_NOT_FOUND", "Card not found"));

        if (!user.getId().equals(card.getCreatedByUserId())) {
            throw ApiException.forbidden("NOT_CARD_OWNER", "You can only manage cards you created");
        }
        return card;
    }

    private CardCategory requireCategory(String categoryCode) {
        return categoryRepository.findByCode(categoryCode)
            .orElseThrow(() -> ApiException.badRequest("UNKNOWN_CATEGORY", "Unknown category code"));
    }

    private Map<UUID, CardTranslation> translationsFor(List<Card> cards) {
        List<UUID> cardIds = cards.stream().map(Card::getId).toList();
        return translationRepository.findByCardIdIn(cardIds).stream()
            .filter(t -> DEFAULT_LANGUAGE.equals(t.getLanguageCode()))
            .collect(Collectors.toMap(t -> t.getCard().getId(), Function.identity()));
    }
}
