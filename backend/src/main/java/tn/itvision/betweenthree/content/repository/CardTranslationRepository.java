package tn.itvision.betweenthree.content.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

import tn.itvision.betweenthree.content.domain.CardTranslation;

public interface CardTranslationRepository extends JpaRepository<CardTranslation, UUID> {

    Optional<CardTranslation> findByCardIdAndLanguageCode(UUID cardId, String languageCode);

    List<CardTranslation> findByCardIdIn(List<UUID> cardIds);
}
