package tn.itvision.betweenthree.sessions.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

import tn.itvision.betweenthree.sessions.domain.SessionParticipantPowerCard;

public interface SessionParticipantPowerCardRepository extends JpaRepository<SessionParticipantPowerCard, UUID> {

    List<SessionParticipantPowerCard> findBySessionId(UUID sessionId);

    List<SessionParticipantPowerCard> findByParticipantId(UUID participantId);

    Optional<SessionParticipantPowerCard> findByIdAndSessionId(UUID id, UUID sessionId);

    void deleteBySessionIdAndParticipantId(UUID sessionId, UUID participantId);
}
