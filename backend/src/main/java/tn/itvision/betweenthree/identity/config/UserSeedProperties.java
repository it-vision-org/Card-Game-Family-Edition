package tn.itvision.betweenthree.identity.config;

import java.util.List;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "app.seed")
public record UserSeedProperties(
    boolean enabled,
    List<SeedPlayer> players
) {

    public record SeedPlayer(
        String publicId,
        String displayName,
        String pin,
        String role
    ) {
    }
}
