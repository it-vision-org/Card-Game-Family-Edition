package tn.itvision.betweenthree.content.service;

import java.io.IOException;
import java.io.InputStream;
import java.util.List;
import java.util.Map;

import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.annotation.Order;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import tools.jackson.databind.json.JsonMapper;

import lombok.extern.slf4j.Slf4j;
import tn.itvision.betweenthree.content.domain.Card;
import tn.itvision.betweenthree.content.domain.CardCategory;
import tn.itvision.betweenthree.content.domain.CardTranslation;
import tn.itvision.betweenthree.content.domain.CardType;
import tn.itvision.betweenthree.content.domain.PowerCardDefinition;
import tn.itvision.betweenthree.content.domain.PowerCardEffect;
import tn.itvision.betweenthree.content.repository.CardCategoryRepository;
import tn.itvision.betweenthree.content.repository.CardRepository;
import tn.itvision.betweenthree.content.repository.CardTranslationRepository;
import tn.itvision.betweenthree.content.repository.PowerCardDefinitionRepository;

/**
 * Loads the versioned card/power-card content from {@code classpath:seed/*.json}
 * into the database on every boot. This is the "seed process" chosen instead of
 * an admin UI for v0 (see plan): the JSON files are the authored source of truth,
 * the database is the runtime source of truth. Upserts are idempotent by natural
 * key (externalKey / code) so re-running on an existing database only applies
 * content changes, never duplicates rows.
 */
@Slf4j
@Component
@Order(0)
public class ContentSeedService implements ApplicationRunner {

    private static final String DEFAULT_LANGUAGE = "ar-TN";

    private final CardCategoryRepository categoryRepository;
    private final CardRepository cardRepository;
    private final CardTranslationRepository translationRepository;
    private final PowerCardDefinitionRepository powerCardRepository;
    private final JsonMapper objectMapper;

    public ContentSeedService(
        CardCategoryRepository categoryRepository,
        CardRepository cardRepository,
        CardTranslationRepository translationRepository,
        PowerCardDefinitionRepository powerCardRepository,
        JsonMapper objectMapper
    ) {
        this.categoryRepository = categoryRepository;
        this.cardRepository = cardRepository;
        this.translationRepository = translationRepository;
        this.powerCardRepository = powerCardRepository;
        this.objectMapper = objectMapper;
    }

    @Override
    @Transactional
    public void run(ApplicationArguments args) throws IOException {
        seedCards();
        seedPowerCards();
    }

    private void seedCards() throws IOException {
        CardSeedFile seedFile = readJson("seed/cards.json", CardSeedFile.class);

        for (SeedCategory seedCategory : seedFile.categories()) {
            CardCategory category = categoryRepository.findByCode(seedCategory.code())
                .orElseGet(() -> new CardCategory(seedCategory.code(), seedCategory.sortOrder()));
            category.setSortOrder(seedCategory.sortOrder());
            category.setActive(true);
            categoryRepository.save(category);
        }

        int created = 0;
        int updated = 0;

        for (SeedCard seedCard : seedFile.cards()) {
            CardCategory category = categoryRepository.findByCode(seedCard.categoryCode())
                .orElseThrow(() -> new IllegalStateException("Unknown category code: " + seedCard.categoryCode()));

            Card card = cardRepository.findByExternalKey(seedCard.externalKey())
                .orElseGet(Card::new);
            boolean isNew = card.getId() == null;

            card.setExternalKey(seedCard.externalKey());
            card.setCategory(category);
            card.setCardType(CardType.valueOf(seedCard.type()));
            card.setEligiblePlayerPublicIds(seedCard.eligiblePlayerRoles());
            card.setAnswerMode(seedCard.answerMode());
            card.setBest(seedCard.best());
            card.setActive(seedCard.active());
            card.setSkippable(seedCard.skippable());
            card.setSupportsScoring(seedCard.supportsScoring());
            card.setSensitivityLevel((short) seedCard.sensitivityLevel());
            card.setEmotionalDepth((short) seedCard.emotionalDepth());
            card.setMinimumPlayers((short) seedCard.minimumPlayers());
            card.setMaximumPlayers(seedCard.maximumPlayers() == null ? null : seedCard.maximumPlayers().shortValue());
            card.setRequiresTimer(seedCard.requirements().timerSeconds() != null);
            card.setTimerSeconds(seedCard.requirements().timerSeconds());
            card.setSelectionWeight(seedCard.selectionWeight());

            card = cardRepository.save(card);

            for (Map.Entry<String, SeedTranslation> entry : seedCard.translations().entrySet()) {
                String languageCode = entry.getKey();
                SeedTranslation seedTranslation = entry.getValue();

                Card savedCard = card;
                CardTranslation translation = translationRepository
                    .findByCardIdAndLanguageCode(card.getId(), languageCode)
                    .orElseGet(() -> new CardTranslation(savedCard, languageCode, null, "", null));

                translation.setTitle(seedTranslation.title());
                translation.setText(seedTranslation.text());
                translation.setInstructions(seedTranslation.instructions());
                translationRepository.save(translation);
            }

            if (isNew) {
                created++;
            } else {
                updated++;
            }
        }

        log.info("Card content seed applied: {} categories, {} cards created, {} cards updated",
            seedFile.categories().size(), created, updated);
    }

    private void seedPowerCards() throws IOException {
        PowerCardSeedFile seedFile = readJson("seed/power_cards.json", PowerCardSeedFile.class);

        for (SeedPowerCard seedPowerCard : seedFile.powerCards()) {
            PowerCardDefinition definition = powerCardRepository.findByCode(seedPowerCard.code())
                .orElseGet(PowerCardDefinition::new);

            definition.setCode(seedPowerCard.code());
            definition.setEffectType(PowerCardEffect.valueOf(seedPowerCard.effectType()));
            definition.setTitle(seedPowerCard.title());
            definition.setDescription(seedPowerCard.description());
            definition.setMaxUsesPerSession((short) seedPowerCard.maxUsesPerSession());
            definition.setActive(seedPowerCard.isActive());

            powerCardRepository.save(definition);
        }

        log.info("Power card seed applied: {} power cards", seedFile.powerCards().size());
    }

    private <T> T readJson(String classpathLocation, Class<T> type) throws IOException {
        try (InputStream inputStream = new ClassPathResource(classpathLocation).getInputStream()) {
            return objectMapper.readValue(inputStream, type);
        }
    }

    private record CardSeedFile(int schemaVersion, List<SeedCategory> categories, List<SeedCard> cards) {
    }

    private record SeedCategory(String code, int sortOrder) {
    }

    private record SeedCard(
        String externalKey,
        String type,
        String categoryCode,
        boolean best,
        boolean active,
        boolean skippable,
        boolean supportsScoring,
        int sensitivityLevel,
        int emotionalDepth,
        int minimumPlayers,
        Integer maximumPlayers,
        int selectionWeight,
        List<String> eligiblePlayerRoles,
        String answerMode,
        SeedRequirements requirements,
        Map<String, SeedTranslation> translations
    ) {
    }

    private record SeedRequirements(Integer timerSeconds, boolean textInput, boolean photo) {
    }

    private record SeedTranslation(String title, String text, String instructions) {
    }

    private record PowerCardSeedFile(int schemaVersion, List<SeedPowerCard> powerCards) {
    }

    private record SeedPowerCard(
        String code,
        String effectType,
        int maxUsesPerSession,
        boolean isActive,
        String title,
        String description
    ) {
    }
}
