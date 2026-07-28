package tn.itvision.betweenthree.identity.api.dto;

import java.util.UUID;

import tn.itvision.betweenthree.identity.domain.AppUser;

public record UserSummary(
    UUID id,
    String publicId,
    String displayName,
    String role
) {
    public static UserSummary from(AppUser user) {
        return new UserSummary(user.getId(), user.getPublicId(), user.getDisplayName(), user.getRole().name());
    }
}
