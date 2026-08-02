package tn.itvision.betweenthree.sessions.api.dto;

import java.util.List;
import java.util.UUID;

public record ParticipantResponse(
    UUID id,
    UUID userId,
    String publicId,
    String displayName,
    int turnPosition,
    int score,
    boolean currentTurn,
    boolean joinedViaCode,
    List<PowerCardAssignmentResponse> powerCards
) {
}
