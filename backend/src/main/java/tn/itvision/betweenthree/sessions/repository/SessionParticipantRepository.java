package tn.itvision.betweenthree.sessions.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

import tn.itvision.betweenthree.sessions.domain.SessionParticipant;

public interface SessionParticipantRepository extends JpaRepository<SessionParticipant, UUID> {

    List<SessionParticipant> findBySessionIdOrderByTurnPositionAsc(UUID sessionId);

    Optional<SessionParticipant> findBySessionIdAndUserId(UUID sessionId, UUID userId);

    long countBySessionId(UUID sessionId);
}
