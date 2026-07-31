package tn.itvision.betweenthree.content.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.domain.Specification;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

import tn.itvision.betweenthree.content.domain.Card;
import tn.itvision.betweenthree.content.domain.CardType;

public interface CardRepository extends JpaRepository<Card, UUID>, JpaSpecificationExecutor<Card> {

    Optional<Card> findByExternalKey(String externalKey);

    List<Card> findByCreatedByUserId(UUID createdByUserId);

    /**
     * Builds the predicate with a {@link Specification} rather than a single
     * JPQL query with {@code :param is null or ...} guards: Postgres cannot
     * infer a bind parameter's type when it is only ever compared to {@code null}
     * (notably for the native {@code card_type} enum column), so every optional
     * filter here is only added to the query when it actually has a value.
     */
    default List<Card> findEligibleCards(
        List<UUID> excludedIds,
        CardType cardType,
        String categoryCode,
        boolean bestOnly
    ) {
        Specification<Card> spec = (root, query, cb) -> cb.and(
            cb.isTrue(root.get("active")),
            cb.isNull(root.get("deletedAt"))
        );

        if (!excludedIds.isEmpty()) {
            spec = spec.and((root, query, cb) -> cb.not(root.get("id").in(excludedIds)));
        }
        if (cardType != null) {
            spec = spec.and((root, query, cb) -> cb.equal(root.get("cardType"), cardType));
        }
        if (categoryCode != null) {
            spec = spec.and((root, query, cb) -> cb.equal(root.get("category").get("code"), categoryCode));
        }
        if (bestOnly) {
            spec = spec.and((root, query, cb) -> cb.isTrue(root.get("best")));
        }

        return findAll(spec);
    }
}
