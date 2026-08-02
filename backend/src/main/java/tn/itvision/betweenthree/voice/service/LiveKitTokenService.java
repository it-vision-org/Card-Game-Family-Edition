package tn.itvision.betweenthree.voice.service;

import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Date;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.stereotype.Service;

import com.nimbusds.jose.JOSEException;
import com.nimbusds.jose.JWSAlgorithm;
import com.nimbusds.jose.JWSHeader;
import com.nimbusds.jose.crypto.MACSigner;
import com.nimbusds.jwt.JWTClaimsSet;
import com.nimbusds.jwt.SignedJWT;

import tn.itvision.betweenthree.voice.config.LiveKitProperties;

/**
 * Signs LiveKit room-access tokens server-side so the API secret never
 * leaves the backend. Unlike {@link tn.itvision.betweenthree.common.security.JwtTokenService},
 * this signs with the raw API secret bytes directly (no SHA-256 key
 * derivation) — LiveKit's own servers verify against the literal secret, per
 * https://docs.livekit.io/realtime/concepts/authentication/.
 */
@Service
@EnableConfigurationProperties(LiveKitProperties.class)
public class LiveKitTokenService {

    private final LiveKitProperties properties;

    public LiveKitTokenService(LiveKitProperties properties) {
        this.properties = properties;
    }

    /**
     * @param roomName             the LiveKit room to grant access to (the game session's id)
     * @param participantIdentity  a stable unique id for this participant within the room (the player's user id)
     * @param participantName      display name shown to other participants
     */
    public String issueToken(String roomName, String participantIdentity, String participantName) {
        Instant now = Instant.now();

        Map<String, Object> videoGrant = new LinkedHashMap<>();
        videoGrant.put("room", roomName);
        videoGrant.put("roomJoin", true);
        videoGrant.put("canPublish", true);
        videoGrant.put("canSubscribe", true);
        videoGrant.put("canPublishData", false);
        // Audio-only by policy (this is a voice-chat feature, not video/telephony) —
        // enforced at the token level, not just left to client-side convention.
        videoGrant.put("canPublishSources", List.of("microphone"));

        JWTClaimsSet claims = new JWTClaimsSet.Builder()
            .issuer(properties.apiKey())
            .subject(participantIdentity)
            .claim("name", participantName)
            .claim("video", videoGrant)
            .issueTime(Date.from(now))
            .notBeforeTime(Date.from(now))
            .expirationTime(Date.from(now.plus(properties.tokenExpiration())))
            .build();

        try {
            SignedJWT signedJWT = new SignedJWT(new JWSHeader(JWSAlgorithm.HS256), claims);
            signedJWT.sign(new MACSigner(properties.apiSecret().getBytes(StandardCharsets.UTF_8)));
            return signedJWT.serialize();
        } catch (JOSEException e) {
            throw new IllegalStateException("Unable to sign LiveKit token", e);
        }
    }
}
