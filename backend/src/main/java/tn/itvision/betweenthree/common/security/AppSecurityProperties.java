package tn.itvision.betweenthree.common.security;

import java.time.Duration;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "app.security")
public record AppSecurityProperties(
    Duration accessTokenExpiration,
    Duration refreshTokenExpiration,
    String accessTokenSecret,
    String refreshTokenSecret
) {
}
