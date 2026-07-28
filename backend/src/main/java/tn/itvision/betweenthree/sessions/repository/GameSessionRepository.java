package tn.itvision.betweenthree.sessions.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

import tn.itvision.betweenthree.sessions.domain.GameSession;

public interface GameSessionRepository extends JpaRepository<GameSession, UUID> {

    Optional<GameSession> findBySessionCode(String sessionCode);

    boolean existsBySessionCode(String sessionCode);

    List<GameSession> findByGroupIdOrderByCreatedAtDesc(UUID groupId);
}
