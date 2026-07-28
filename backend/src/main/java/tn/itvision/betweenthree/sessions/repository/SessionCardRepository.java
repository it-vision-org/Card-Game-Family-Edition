package tn.itvision.betweenthree.sessions.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

import tn.itvision.betweenthree.sessions.domain.SessionCard;
import tn.itvision.betweenthree.sessions.domain.SessionCardStatus;

public interface SessionCardRepository extends JpaRepository<SessionCard, UUID> {

    List<SessionCard> findBySessionIdOrderByDrawOrderAsc(UUID sessionId);

    Optional<SessionCard> findBySessionIdAndStatus(UUID sessionId, SessionCardStatus status);

    Optional<SessionCard> findFirstBySessionIdAndStatusOrderByDrawOrderAsc(UUID sessionId, SessionCardStatus status);
}
