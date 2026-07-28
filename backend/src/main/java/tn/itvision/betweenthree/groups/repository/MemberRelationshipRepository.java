package tn.itvision.betweenthree.groups.repository;

import java.util.List;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

import tn.itvision.betweenthree.groups.domain.MemberRelationship;

public interface MemberRelationshipRepository extends JpaRepository<MemberRelationship, UUID> {

    List<MemberRelationship> findByGroupId(UUID groupId);
}
