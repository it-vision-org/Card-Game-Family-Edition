package tn.itvision.betweenthree.sessions.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import tn.itvision.betweenthree.sessions.domain.CardTrash;

public interface CardTrashRepository extends JpaRepository<CardTrash, UUID> {

    @Query("select t.card.id from CardTrash t where t.group.id = :groupId")
    List<UUID> findActiveTrashedCardIds(@Param("groupId") UUID groupId);

    List<CardTrash> findByGroupId(UUID groupId);

    Optional<CardTrash> findByGroupIdAndCardId(UUID groupId, UUID cardId);

    List<CardTrash> findByGroupIdAndCardIdIn(UUID groupId, List<UUID> cardIds);
}
