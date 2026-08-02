package tn.itvision.betweenthree.voice.config;

import java.time.Duration;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "app.livekit")
public record LiveKitProperties(
    String apiKey,
    String apiSecret,
    String wsUrl,
    Duration tokenExpiration
) {
}
