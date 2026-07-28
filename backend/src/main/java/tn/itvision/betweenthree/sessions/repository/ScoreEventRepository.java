package tn.itvision.betweenthree.sessions.repository;

import java.util.List;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

import tn.itvision.betweenthree.sessions.domain.ScoreEvent;

public interface ScoreEventRepository extends JpaRepository<ScoreEvent, UUID> {

    List<ScoreEvent> findBySessionIdOrderByCreatedAtAsc(UUID sessionId);
}
