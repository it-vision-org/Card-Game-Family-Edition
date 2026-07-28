package tn.itvision.betweenthree.sessions.api.dto;

import java.util.UUID;

public record PowerCardAssignmentResponse(
    UUID id,
    String code,
    String title,
    String description,
    boolean used,
    UUID targetParticipantId
) {
}
