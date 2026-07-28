package tn.itvision.betweenthree.groups.api.dto;

import java.util.List;
import java.util.UUID;

public record GroupResponse(
    UUID id,
    String name,
    UUID ownerId,
    List<MemberResponse> members,
    List<RelationshipResponse> relationships
) {
}
