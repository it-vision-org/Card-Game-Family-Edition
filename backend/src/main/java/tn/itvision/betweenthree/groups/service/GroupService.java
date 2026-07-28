package tn.itvision.betweenthree.groups.service;

import java.util.List;
import java.util.UUID;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import tn.itvision.betweenthree.common.api.ApiException;
import tn.itvision.betweenthree.groups.api.dto.GroupResponse;
import tn.itvision.betweenthree.groups.api.dto.MemberResponse;
import tn.itvision.betweenthree.groups.api.dto.RelationshipResponse;
import tn.itvision.betweenthree.groups.domain.GameGroup;
import tn.itvision.betweenthree.groups.domain.GroupMember;
import tn.itvision.betweenthree.groups.domain.MemberRelationship;
import tn.itvision.betweenthree.groups.domain.RelationshipType;
import tn.itvision.betweenthree.groups.repository.GameGroupRepository;
import tn.itvision.betweenthree.groups.repository.GroupMemberRepository;
import tn.itvision.betweenthree.groups.repository.MemberRelationshipRepository;
import tn.itvision.betweenthree.identity.domain.AppUser;
import tn.itvision.betweenthree.identity.repository.AppUserRepository;

@Service
public class GroupService {

    private final GameGroupRepository groupRepository;
    private final GroupMemberRepository groupMemberRepository;
    private final MemberRelationshipRepository relationshipRepository;
    private final AppUserRepository userRepository;

    public GroupService(
        GameGroupRepository groupRepository,
        GroupMemberRepository groupMemberRepository,
        MemberRelationshipRepository relationshipRepository,
        AppUserRepository userRepository
    ) {
        this.groupRepository = groupRepository;
        this.groupMemberRepository = groupMemberRepository;
        this.relationshipRepository = relationshipRepository;
        this.userRepository = userRepository;
    }

    @Transactional
    public GameGroup createGroup(String name, AppUser owner) {
        GameGroup group = groupRepository.save(new GameGroup(name, owner));
        groupMemberRepository.save(new GroupMember(group, owner, 0));
        return group;
    }

    @Transactional
    public GroupMember addMember(UUID groupId, String memberPublicId) {
        GameGroup group = requireGroup(groupId);
        AppUser user = userRepository.findByPublicId(memberPublicId.trim().toUpperCase())
            .orElseThrow(() -> ApiException.notFound("USER_NOT_FOUND", "No player with that identifier"));

        if (groupMemberRepository.findById(new tn.itvision.betweenthree.groups.domain.GroupMemberId(groupId, user.getId())).isPresent()) {
            throw ApiException.conflict("ALREADY_MEMBER", "Player is already a member of this group");
        }

        int nextPosition = (int) groupMemberRepository.countByGroupId(groupId);
        return groupMemberRepository.save(new GroupMember(group, user, nextPosition));
    }

    @Transactional
    public MemberRelationship defineRelationship(
        UUID groupId,
        String memberAPublicId,
        String memberBPublicId,
        RelationshipType type
    ) {
        GameGroup group = requireGroup(groupId);
        AppUser userA = userRepository.findByPublicId(memberAPublicId.trim().toUpperCase())
            .orElseThrow(() -> ApiException.notFound("USER_NOT_FOUND", "No player with that identifier"));
        AppUser userB = userRepository.findByPublicId(memberBPublicId.trim().toUpperCase())
            .orElseThrow(() -> ApiException.notFound("USER_NOT_FOUND", "No player with that identifier"));

        if (userA.getId().equals(userB.getId())) {
            throw ApiException.badRequest("INVALID_RELATIONSHIP", "A relationship requires two different players");
        }

        // The DB enforces member_a_user_id < member_b_user_id using Postgres's
        // byte-wise uuid comparison. java.util.UUID#compareTo compares the two
        // halves as SIGNED longs, which disagrees with Postgres for roughly half
        // of all UUIDs — comparing the canonical string form matches Postgres.
        boolean aFirst = userA.getId().toString().compareTo(userB.getId().toString()) < 0;
        AppUser first = aFirst ? userA : userB;
        AppUser second = aFirst ? userB : userA;

        return relationshipRepository.findByGroupId(groupId).stream()
            .filter(r -> r.getMemberA().getId().equals(first.getId()) && r.getMemberB().getId().equals(second.getId()))
            .findFirst()
            .map(existing -> {
                existing.setRelationshipType(type);
                return existing;
            })
            .orElseGet(() -> relationshipRepository.save(new MemberRelationship(group, first, second, type)));
    }

    @Transactional(readOnly = true)
    public GameGroup requireGroup(UUID groupId) {
        return groupRepository.findById(groupId)
            .orElseThrow(() -> ApiException.notFound("GROUP_NOT_FOUND", "Group not found"));
    }

    @Transactional(readOnly = true)
    public GroupResponse toResponse(UUID groupId) {
        GameGroup group = requireGroup(groupId);
        List<MemberResponse> members = groupMemberRepository.findByGroupIdOrderByTurnPositionAsc(groupId).stream()
            .map(MemberResponse::from)
            .toList();
        List<RelationshipResponse> relationships = relationshipRepository.findByGroupId(groupId).stream()
            .map(RelationshipResponse::from)
            .toList();

        return new GroupResponse(group.getId(), group.getName(), group.getOwner().getId(), members, relationships);
    }

    @Transactional(readOnly = true)
    public List<GameGroup> listGroupsForUser(UUID userId) {
        return groupMemberRepository.findByUserId(userId).stream()
            .map(GroupMember::getGroup)
            .toList();
    }
}
