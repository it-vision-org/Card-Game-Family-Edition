package tn.itvision.betweenthree.groups.repository;

import java.util.List;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

import tn.itvision.betweenthree.groups.domain.GroupMember;
import tn.itvision.betweenthree.groups.domain.GroupMemberId;

public interface GroupMemberRepository extends JpaRepository<GroupMember, GroupMemberId> {

    List<GroupMember> findByGroupIdOrderByTurnPositionAsc(UUID groupId);

    long countByGroupId(UUID groupId);

    List<GroupMember> findByUserId(UUID userId);
}
