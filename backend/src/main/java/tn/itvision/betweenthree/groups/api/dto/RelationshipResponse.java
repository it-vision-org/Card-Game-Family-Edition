package tn.itvision.betweenthree.groups.api.dto;

import java.util.UUID;

import tn.itvision.betweenthree.groups.domain.MemberRelationship;

public record RelationshipResponse(
    UUID id,
    String memberAPublicId,
    String memberBPublicId,
    String relationshipType
) {
    public static RelationshipResponse from(MemberRelationship relationship) {
        return new RelationshipResponse(
            relationship.getId(),
            relationship.getMemberA().getPublicId(),
            relationship.getMemberB().getPublicId(),
            relationship.getRelationshipType().name()
        );
    }
}
