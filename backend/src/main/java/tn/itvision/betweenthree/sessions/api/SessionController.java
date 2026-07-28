package tn.itvision.betweenthree.sessions.api;

import java.util.UUID;

import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import jakarta.validation.Valid;
import tn.itvision.betweenthree.common.security.CurrentUserProvider;
import tn.itvision.betweenthree.identity.domain.AppUser;
import tn.itvision.betweenthree.sessions.api.dto.AddParticipantRequest;
import tn.itvision.betweenthree.sessions.api.dto.AwardScoreRequest;
import tn.itvision.betweenthree.sessions.api.dto.ChoosePowerCardsRequest;
import tn.itvision.betweenthree.sessions.api.dto.CreateSessionRequest;
import tn.itvision.betweenthree.sessions.api.dto.JoinSessionRequest;
import tn.itvision.betweenthree.sessions.api.dto.SessionStateResponse;
import tn.itvision.betweenthree.sessions.api.dto.UsePowerCardRequest;
import tn.itvision.betweenthree.sessions.service.SessionService;

@RestController
@RequestMapping("/api/v1/sessions")
public class SessionController {

    private final SessionService sessionService;
    private final CurrentUserProvider currentUserProvider;

    public SessionController(SessionService sessionService, CurrentUserProvider currentUserProvider) {
        this.sessionService = sessionService;
        this.currentUserProvider = currentUserProvider;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public SessionStateResponse createSession(@Valid @RequestBody CreateSessionRequest request, @AuthenticationPrincipal Jwt jwt) {
        AppUser creator = currentUserProvider.require(jwt);
        return sessionService.createSession(
            request.groupId(),
            creator,
            request.gameMode(),
            request.categoryCode(),
            request.requestedCardCount(),
            request.scoringEnabled()
        );
    }

    @PostMapping("/join")
    public SessionStateResponse join(@Valid @RequestBody JoinSessionRequest request, @AuthenticationPrincipal Jwt jwt) {
        AppUser user = currentUserProvider.require(jwt);
        return sessionService.joinByCode(request.sessionCode(), user);
    }

    @GetMapping("/{sessionId}")
    public SessionStateResponse getState(@PathVariable UUID sessionId) {
        return sessionService.getState(sessionId);
    }

    @PostMapping("/{sessionId}/participants")
    public SessionStateResponse addParticipant(@PathVariable UUID sessionId, @Valid @RequestBody AddParticipantRequest request) {
        return sessionService.addParticipant(sessionId, request.userPublicId());
    }

    @PostMapping("/{sessionId}/participants/{participantId}/power-cards")
    public SessionStateResponse choosePowerCards(
        @PathVariable UUID sessionId,
        @PathVariable UUID participantId,
        @Valid @RequestBody ChoosePowerCardsRequest request
    ) {
        return sessionService.choosePowerCards(sessionId, participantId, request.powerCardDefinitionIds());
    }

    @PostMapping("/{sessionId}/start")
    public SessionStateResponse start(@PathVariable UUID sessionId) {
        return sessionService.start(sessionId);
    }

    @PostMapping("/{sessionId}/cards/{sessionCardId}/complete")
    public SessionStateResponse completeCard(@PathVariable UUID sessionId, @PathVariable UUID sessionCardId) {
        return sessionService.completeCurrentCard(sessionId, sessionCardId);
    }

    @PostMapping("/{sessionId}/cards/{sessionCardId}/skip")
    public SessionStateResponse skipCard(@PathVariable UUID sessionId, @PathVariable UUID sessionCardId) {
        return sessionService.skipCurrentCard(sessionId, sessionCardId);
    }

    @PostMapping("/{sessionId}/power-cards/{assignmentId}/use")
    public SessionStateResponse usePowerCard(
        @PathVariable UUID sessionId,
        @PathVariable UUID assignmentId,
        @RequestBody(required = false) UsePowerCardRequest request
    ) {
        UUID targetParticipantId = request != null ? request.targetParticipantId() : null;
        return sessionService.usePowerCard(sessionId, assignmentId, targetParticipantId);
    }

    @PostMapping("/{sessionId}/scores")
    public SessionStateResponse awardScore(@PathVariable UUID sessionId, @Valid @RequestBody AwardScoreRequest request) {
        return sessionService.awardScore(sessionId, request.participantId(), request.points(), request.reasonCode(), request.note());
    }

    @PostMapping("/{sessionId}/pause")
    public SessionStateResponse pause(@PathVariable UUID sessionId) {
        return sessionService.pause(sessionId);
    }

    @PostMapping("/{sessionId}/resume")
    public SessionStateResponse resume(@PathVariable UUID sessionId) {
        return sessionService.resume(sessionId);
    }

    @PostMapping("/{sessionId}/cancel")
    public SessionStateResponse cancel(@PathVariable UUID sessionId) {
        return sessionService.cancel(sessionId);
    }
}
