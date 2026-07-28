package tn.itvision.betweenthree.content.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

import tn.itvision.betweenthree.content.domain.PowerCardDefinition;

public interface PowerCardDefinitionRepository extends JpaRepository<PowerCardDefinition, UUID> {

    Optional<PowerCardDefinition> findByCode(String code);

    List<PowerCardDefinition> findByActiveTrue();
}
