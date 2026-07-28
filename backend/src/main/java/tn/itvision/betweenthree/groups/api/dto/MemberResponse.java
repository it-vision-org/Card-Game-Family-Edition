package tn.itvision.betweenthree.groups.api.dto;

import java.util.UUID;

import tn.itvision.betweenthree.groups.domain.GroupMember;

public record MemberResponse(
    UUID userId,
    String publicId,
    String displayName,
    Integer turnPosition
) {
    public static MemberResponse from(GroupMember member) {
        return new MemberResponse(
            member.getUser().getId(),
            member.getUser().getPublicId(),
            member.getUser().getDisplayName(),
            member.getTurnPosition()
        );
    }
}
