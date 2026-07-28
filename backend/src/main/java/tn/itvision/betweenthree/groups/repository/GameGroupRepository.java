package tn.itvision.betweenthree.groups.repository;

import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

import tn.itvision.betweenthree.groups.domain.GameGroup;

public interface GameGroupRepository extends JpaRepository<GameGroup, UUID> {
}
