package tn.itvision.betweenthree.sessions.api.dto;

import java.util.UUID;

public record UsePowerCardRequest(
    UUID targetParticipantId
) {
}
