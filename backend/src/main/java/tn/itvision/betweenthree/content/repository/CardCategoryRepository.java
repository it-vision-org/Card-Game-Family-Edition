package tn.itvision.betweenthree.content.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

import tn.itvision.betweenthree.content.domain.CardCategory;

public interface CardCategoryRepository extends JpaRepository<CardCategory, UUID> {

    Optional<CardCategory> findByCode(String code);

    List<CardCategory> findAllByOrderBySortOrderAsc();
}
