package tn.itvision.betweenthree.voice.api;

import java.util.UUID;

import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import tn.itvision.betweenthree.common.api.ApiException;
import tn.itvision.betweenthree.common.security.CurrentUserProvider;
import tn.itvision.betweenthree.identity.domain.AppUser;
import tn.itvision.betweenthree.sessions.domain.GameSession;
import tn.itvision.betweenthree.sessions.repository.GameSessionRepository;
import tn.itvision.betweenthree.sessions.repository.SessionParticipantRepository;
import tn.itvision.betweenthree.voice.api.dto.VoiceTokenResponse;
import tn.itvision.betweenthree.voice.config.LiveKitProperties;
import tn.itvision.betweenthree.voice.service.LiveKitTokenService;

/**
 * Issues LiveKit room-access tokens for the voice-chat feature. The LiveKit
 * room is the game session itself (room name == session id), so every
 * participant in a session joins the same room regardless of which screen
 * (lobby or active game) they're currently on.
 */
@RestController
@RequestMapping("/api/v1/sessions/{sessionId}/voice")
public class VoiceController {

    private final GameSessionRepository sessionRepository;
    private final SessionParticipantRepository participantRepository;
    private final CurrentUserProvider currentUserProvider;
    private final LiveKitTokenService tokenService;
    private final LiveKitProperties properties;

    public VoiceController(
        GameSessionRepository sessionRepository,
        SessionParticipantRepository participantRepository,
        CurrentUserProvider currentUserProvider,
        LiveKitTokenService tokenService,
        LiveKitProperties properties
    ) {
        this.sessionRepository = sessionRepository;
        this.participantRepository = participantRepository;
        this.currentUserProvider = currentUserProvider;
        this.tokenService = tokenService;
        this.properties = properties;
    }

    @PostMapping("/token")
    public VoiceTokenResponse issueToken(@PathVariable UUID sessionId, @AuthenticationPrincipal Jwt jwt) {
        AppUser user = currentUserProvider.require(jwt);

        GameSession session = sessionRepository.findById(sessionId)
            .orElseThrow(() -> ApiException.notFound("SESSION_NOT_FOUND", "Session not found"));

        boolean isParticipant = participantRepository.findBySessionIdAndUserId(session.getId(), user.getId()).isPresent();
        if (!isParticipant) {
            throw ApiException.forbidden("NOT_SESSION_PARTICIPANT", "You are not a participant in this session");
        }

        String roomName = session.getId().toString();
        String token = tokenService.issueToken(roomName, user.getId().toString(), user.getDisplayName());

        return new VoiceTokenResponse(properties.wsUrl(), token, roomName);
    }
}
