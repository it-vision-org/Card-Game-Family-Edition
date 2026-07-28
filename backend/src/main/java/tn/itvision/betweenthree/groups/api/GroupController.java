package tn.itvision.betweenthree.groups.api;

import java.util.List;
import java.util.UUID;

import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import jakarta.validation.Valid;
import tn.itvision.betweenthree.common.api.ApiException;
import tn.itvision.betweenthree.common.security.CurrentUserProvider;
import tn.itvision.betweenthree.groups.api.dto.AddMemberRequest;
import tn.itvision.betweenthree.groups.api.dto.CreateGroupRequest;
import tn.itvision.betweenthree.groups.api.dto.DefineRelationshipRequest;
import tn.itvision.betweenthree.groups.api.dto.GroupResponse;
import tn.itvision.betweenthree.groups.domain.GameGroup;
import tn.itvision.betweenthree.groups.domain.RelationshipType;
import tn.itvision.betweenthree.identity.domain.AppUser;
import tn.itvision.betweenthree.groups.service.GroupService;
import tn.itvision.betweenthree.sessions.api.dto.SessionSummaryResponse;
import tn.itvision.betweenthree.sessions.service.SessionService;

@RestController
@RequestMapping("/api/v1/groups")
public class GroupController {

    private final GroupService groupService;
    private final CurrentUserProvider currentUserProvider;
    private final SessionService sessionService;

    public GroupController(GroupService groupService, CurrentUserProvider currentUserProvider, SessionService sessionService) {
        this.groupService = groupService;
        this.currentUserProvider = currentUserProvider;
        this.sessionService = sessionService;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public GroupResponse createGroup(@Valid @RequestBody CreateGroupRequest request, @AuthenticationPrincipal Jwt jwt) {
        AppUser owner = currentUserProvider.require(jwt);
        GameGroup group = groupService.createGroup(request.name(), owner);
        return groupService.toResponse(group.getId());
    }

    @GetMapping
    public List<GroupResponse> listMyGroups(@AuthenticationPrincipal Jwt jwt) {
        AppUser user = currentUserProvider.require(jwt);
        return groupService.listGroupsForUser(user.getId()).stream()
            .map(group -> groupService.toResponse(group.getId()))
            .toList();
    }

    @GetMapping("/{groupId}")
    public GroupResponse getGroup(@PathVariable UUID groupId) {
        return groupService.toResponse(groupId);
    }

    @PostMapping("/{groupId}/members")
    public GroupResponse addMember(@PathVariable UUID groupId, @Valid @RequestBody AddMemberRequest request) {
        groupService.addMember(groupId, request.publicId());
        return groupService.toResponse(groupId);
    }

    @PostMapping("/{groupId}/relationships")
    public GroupResponse defineRelationship(@PathVariable UUID groupId, @Valid @RequestBody DefineRelationshipRequest request) {
        RelationshipType type = parseRelationshipType(request.relationshipType());
        groupService.defineRelationship(groupId, request.memberAPublicId(), request.memberBPublicId(), type);
        return groupService.toResponse(groupId);
    }

    @GetMapping("/{groupId}/sessions")
    public List<SessionSummaryResponse> listSessions(@PathVariable UUID groupId) {
        return sessionService.history(groupId);
    }

    private RelationshipType parseRelationshipType(String value) {
        try {
            return RelationshipType.valueOf(value);
        } catch (IllegalArgumentException e) {
            throw ApiException.badRequest("INVALID_RELATIONSHIP_TYPE", "Unknown relationship type: " + value);
        }
    }
}
