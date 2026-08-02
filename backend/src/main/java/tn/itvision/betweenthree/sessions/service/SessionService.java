package tn.itvision.betweenthree.sessions.service;

import java.security.SecureRandom;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Random;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import tn.itvision.betweenthree.common.api.ApiException;
import tn.itvision.betweenthree.content.domain.Card;
import tn.itvision.betweenthree.content.domain.CardTranslation;
import tn.itvision.betweenthree.content.domain.PowerCardDefinition;
import tn.itvision.betweenthree.content.domain.PowerCardEffect;
import tn.itvision.betweenthree.content.repository.CardRepository;
import tn.itvision.betweenthree.content.repository.CardTranslationRepository;
import tn.itvision.betweenthree.content.repository.PowerCardDefinitionRepository;
import tn.itvision.betweenthree.groups.domain.GameGroup;
import tn.itvision.betweenthree.groups.repository.GroupMemberRepository;
import tn.itvision.betweenthree.groups.service.GroupService;
import tn.itvision.betweenthree.identity.domain.AppUser;
import tn.itvision.betweenthree.identity.repository.AppUserRepository;
import tn.itvision.betweenthree.realtime.SessionSocketHandler;
import tn.itvision.betweenthree.sessions.api.dto.CurrentCardResponse;
import tn.itvision.betweenthree.sessions.api.dto.ParticipantResponse;
import tn.itvision.betweenthree.sessions.api.dto.PowerCardAssignmentResponse;
import tn.itvision.betweenthree.sessions.api.dto.SessionStateResponse;
import tn.itvision.betweenthree.sessions.api.dto.SessionSummaryResponse;
import tn.itvision.betweenthree.settings.service.GameSettingsService;
import tn.itvision.betweenthree.sessions.domain.CardTrash;
import tn.itvision.betweenthree.sessions.domain.GameMode;
import tn.itvision.betweenthree.sessions.domain.GameSession;
import tn.itvision.betweenthree.sessions.domain.SessionCard;
import tn.itvision.betweenthree.sessions.domain.SessionCardStatus;
import tn.itvision.betweenthree.sessions.domain.SessionParticipant;
import tn.itvision.betweenthree.sessions.domain.SessionParticipantPowerCard;
import tn.itvision.betweenthree.sessions.domain.SessionStatus;
import tn.itvision.betweenthree.sessions.repository.CardTrashRepository;
import tn.itvision.betweenthree.sessions.repository.GameSessionRepository;
import tn.itvision.betweenthree.sessions.repository.ScoreEventRepository;
import tn.itvision.betweenthree.sessions.domain.ScoreEvent;
import tn.itvision.betweenthree.sessions.repository.SessionCardRepository;
import tn.itvision.betweenthree.sessions.repository.SessionParticipantPowerCardRepository;
import tn.itvision.betweenthree.sessions.repository.SessionParticipantRepository;

/**
 * Core gameplay state machine: session creation/joining, the deterministic
 * seeded deck build (excluding the group's card trash), turn advancement,
 * power-card usage, and scoring. Every mutation is a single {@code @Transactional}
 * method that saves {@link GameSession} last, so JPA's optimistic {@code @Version}
 * check catches concurrent double-draws/advances (surfaced as 409 by
 * {@link tn.itvision.betweenthree.common.api.GlobalExceptionHandler}), and then
 * broadcasts the fresh state over the session's WebSocket channel.
 */
@Service
public class SessionService {

    private static final String DEFAULT_LANGUAGE = "ar-TN";
    private static final String CODE_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
    private static final int SESSION_CODE_LENGTH = 6;

    private final GameSessionRepository gameSessionRepository;
    private final SessionParticipantRepository participantRepository;
    private final SessionCardRepository sessionCardRepository;
    private final SessionParticipantPowerCardRepository powerCardAssignmentRepository;
    private final ScoreEventRepository scoreEventRepository;
    private final CardTrashRepository cardTrashRepository;
    private final CardRepository cardRepository;
    private final CardTranslationRepository cardTranslationRepository;
    private final PowerCardDefinitionRepository powerCardDefinitionRepository;
    private final AppUserRepository userRepository;
    private final GroupMemberRepository groupMemberRepository;
    private final GroupService groupService;
    private final SessionSocketHandler sessionSocketHandler;
    private final GameSettingsService gameSettingsService;
    private final SecureRandom secureRandom = new SecureRandom();

    public SessionService(
        GameSessionRepository gameSessionRepository,
        SessionParticipantRepository participantRepository,
        SessionCardRepository sessionCardRepository,
        SessionParticipantPowerCardRepository powerCardAssignmentRepository,
        ScoreEventRepository scoreEventRepository,
        CardTrashRepository cardTrashRepository,
        CardRepository cardRepository,
        CardTranslationRepository cardTranslationRepository,
        PowerCardDefinitionRepository powerCardDefinitionRepository,
        AppUserRepository userRepository,
        GroupMemberRepository groupMemberRepository,
        GroupService groupService,
        SessionSocketHandler sessionSocketHandler,
        GameSettingsService gameSettingsService
    ) {
        this.gameSessionRepository = gameSessionRepository;
        this.participantRepository = participantRepository;
        this.sessionCardRepository = sessionCardRepository;
        this.powerCardAssignmentRepository = powerCardAssignmentRepository;
        this.scoreEventRepository = scoreEventRepository;
        this.cardTrashRepository = cardTrashRepository;
        this.cardRepository = cardRepository;
        this.cardTranslationRepository = cardTranslationRepository;
        this.powerCardDefinitionRepository = powerCardDefinitionRepository;
        this.userRepository = userRepository;
        this.groupMemberRepository = groupMemberRepository;
        this.groupService = groupService;
        this.sessionSocketHandler = sessionSocketHandler;
        this.gameSettingsService = gameSettingsService;
    }

    @Transactional
    public SessionStateResponse createSession(
        UUID groupId,
        AppUser creator,
        String gameModeValue,
        String categoryCode,
        int requestedCardCount,
        boolean scoringEnabled
    ) {
        GameGroup group = groupService.requireGroup(groupId);
        requireGroupMember(groupId, creator.getId());

        GameMode mode = parseGameMode(gameModeValue);
        if (mode == GameMode.CATEGORY && (categoryCode == null || categoryCode.isBlank())) {
            throw ApiException.badRequest("CATEGORY_REQUIRED", "categoryCode is required for CATEGORY mode");
        }

        // Only a loose sanity check here: whether the mode/category/best pool has
        // *enough* cards overall. The per-turn eligibility check can't run until
        // start() — it depends on the final participant list and starting player,
        // neither of which is known yet.
        validatePoolSize(group, mode, categoryCode, requestedCardCount);

        long seed = secureRandom.nextLong();

        GameSession session = new GameSession();
        session.setGroup(group);
        session.setCreatedBy(creator);
        session.setSessionCode(generateUniqueSessionCode());
        session.setGameMode(mode);
        session.setCategoryCode(mode == GameMode.CATEGORY ? categoryCode : null);
        session.setScoringEnabled(scoringEnabled);
        session.setRequestedCardCount(requestedCardCount);
        session.setRandomSeed(seed);
        session.setStatus(SessionStatus.WAITING_FOR_PLAYERS);
        session = gameSessionRepository.save(session);

        addParticipantInternal(session, creator, false);

        return toStateResponse(session);
    }

    @Transactional
    public SessionStateResponse joinByCode(String sessionCode, AppUser user) {
        GameSession session = requireSessionByCode(sessionCode);
        requireGroupMember(session.getGroup().getId(), user.getId());

        if (participantRepository.findBySessionIdAndUserId(session.getId(), user.getId()).isEmpty()) {
            addParticipantInternal(session, user, true);
        }

        return toStateResponse(session);
    }

    @Transactional
    public SessionStateResponse addParticipant(UUID sessionId, String memberPublicId) {
        GameSession session = requireSession(sessionId);
        AppUser user = userRepository.findByPublicId(memberPublicId.trim().toUpperCase())
            .orElseThrow(() -> ApiException.notFound("USER_NOT_FOUND", "No player with that identifier"));
        requireGroupMember(session.getGroup().getId(), user.getId());

        if (participantRepository.findBySessionIdAndUserId(sessionId, user.getId()).isEmpty()) {
            addParticipantInternal(session, user, false);
        }

        return toStateResponse(session);
    }

    @Transactional(readOnly = true)
    public SessionStateResponse getState(UUID sessionId) {
        return toStateResponse(requireSession(sessionId));
    }

    @Transactional(readOnly = true)
    public List<SessionSummaryResponse> history(UUID groupId) {
        return gameSessionRepository.findByGroupIdOrderByCreatedAtDesc(groupId).stream()
            .map(s -> new SessionSummaryResponse(
                s.getId(), s.getSessionCode(), s.getStatus().name(), s.getGameMode().name(),
                s.getRequestedCardCount(), s.getCompletedCardCount(), s.getStartedAt(), s.getCompletedAt()
            ))
            .toList();
    }

    @Transactional
    public SessionStateResponse start(UUID sessionId) {
        GameSession session = requireSession(sessionId);
        if (session.getStatus() != SessionStatus.WAITING_FOR_PLAYERS && session.getStatus() != SessionStatus.READY) {
            throw ApiException.conflict("INVALID_STATE", "Session cannot be started from status " + session.getStatus());
        }

        List<SessionParticipant> participants = participantRepository.findBySessionIdOrderByTurnPositionAsc(sessionId);
        if (participants.size() < 2) {
            throw ApiException.conflict("NOT_ENOUGH_PLAYERS", "At least two players are required to start a session");
        }

        requireEveryoneHasChosenPowerCards(session, participants);

        int startingIndex = new Random(session.getRandomSeed()).nextInt(participants.size());
        SessionParticipant startingPlayer = participants.get(startingIndex);

        List<Card> sequence = buildEligibleSequence(session, participants, startingIndex);
        for (int i = 0; i < sequence.size(); i++) {
            sessionCardRepository.save(new SessionCard(session, sequence.get(i), i));
        }

        session.setStatus(SessionStatus.IN_PROGRESS);
        session.setStartedAt(Instant.now());
        session.setCurrentTurnPosition(startingPlayer.getTurnPosition());

        sessionCardRepository.findFirstBySessionIdAndStatusOrderByDrawOrderAsc(sessionId, SessionCardStatus.PENDING)
            .ifPresent(card -> {
                card.setStatus(SessionCardStatus.DRAWN);
                card.setDrawnAt(Instant.now());
                card.setActivePlayer(startingPlayer);
                sessionCardRepository.save(card);
            });

        GameSession saved = gameSessionRepository.saveAndFlush(session);
        return broadcastAndReturn(saved);
    }

    @Transactional
    public SessionStateResponse choosePowerCards(UUID sessionId, UUID participantId, List<UUID> powerCardDefinitionIds) {
        GameSession session = requireSession(sessionId);
        if (session.getStatus() != SessionStatus.WAITING_FOR_PLAYERS && session.getStatus() != SessionStatus.READY) {
            throw ApiException.conflict("INVALID_STATE", "Power cards can only be chosen before the session starts");
        }

        SessionParticipant participant = participantRepository.findById(participantId)
            .filter(p -> p.getSession().getId().equals(sessionId))
            .orElseThrow(() -> ApiException.notFound("PARTICIPANT_NOT_FOUND", "Participant not found in this session"));

        int requiredCount = gameSettingsService.getSettings().getPowerCardsPerPlayer();
        if (powerCardDefinitionIds.size() != requiredCount) {
            throw ApiException.badRequest(
                "WRONG_POWER_CARD_COUNT",
                "Exactly " + requiredCount + " power cards must be chosen"
            );
        }

        Map<UUID, PowerCardDefinition> definitionsById = powerCardDefinitionRepository
            .findAllById(powerCardDefinitionIds).stream()
            .collect(Collectors.toMap(PowerCardDefinition::getId, d -> d));
        for (UUID id : powerCardDefinitionIds) {
            if (!definitionsById.containsKey(id)) {
                throw ApiException.badRequest("INVALID_POWER_CARD", "Unknown power card definition: " + id);
            }
        }

        powerCardAssignmentRepository.deleteBySessionIdAndParticipantId(sessionId, participantId);
        for (UUID id : powerCardDefinitionIds) {
            powerCardAssignmentRepository.save(
                new SessionParticipantPowerCard(session, participant, definitionsById.get(id))
            );
        }

        List<SessionParticipant> participants = participantRepository.findBySessionIdOrderByTurnPositionAsc(sessionId);
        if (session.getStatus() == SessionStatus.WAITING_FOR_PLAYERS
            && participants.size() >= 2
            && everyoneHasChosenPowerCards(session, participants, requiredCount)) {
            session.setStatus(SessionStatus.READY);
        }

        // Picking cards only changes child rows (session_participant_power_cards),
        // not the session entity itself, so Hibernate's dirty checking would skip
        // the UPDATE and leave @Version unchanged unless we touch a session field
        // here — the client relies on a strictly increasing version to reject a
        // stale WebSocket/HTTP response that arrives out of order.
        session.setUpdatedAt(Instant.now());

        return broadcastAndReturn(gameSessionRepository.saveAndFlush(session));
    }

    @Transactional
    public SessionStateResponse completeCurrentCard(UUID sessionId, UUID sessionCardId) {
        GameSession session = requireSession(sessionId);
        requireStatus(session, SessionStatus.IN_PROGRESS);
        SessionCard card = requireDrawnCard(session, sessionCardId);

        card.setStatus(SessionCardStatus.COMPLETED);
        card.setCompletedAt(Instant.now());
        sessionCardRepository.save(card);
        trashCard(session, card);
        advanceTurn(session);

        GameSession saved = gameSessionRepository.saveAndFlush(session);
        return broadcastAndReturn(saved);
    }

    @Transactional
    public SessionStateResponse skipCurrentCard(UUID sessionId, UUID sessionCardId) {
        GameSession session = requireSession(sessionId);
        requireStatus(session, SessionStatus.IN_PROGRESS);
        SessionCard card = requireDrawnCard(session, sessionCardId);

        if (!card.getCard().isSkippable()) {
            throw ApiException.badRequest("NOT_SKIPPABLE", "This card cannot be skipped");
        }

        card.setStatus(SessionCardStatus.SKIPPED);
        card.setCompletedAt(Instant.now());
        sessionCardRepository.save(card);
        trashCard(session, card);
        advanceTurn(session);

        GameSession saved = gameSessionRepository.saveAndFlush(session);
        return broadcastAndReturn(saved);
    }

    @Transactional
    public SessionStateResponse usePowerCard(UUID sessionId, UUID assignmentId, UUID targetParticipantId) {
        GameSession session = requireSession(sessionId);
        requireStatus(session, SessionStatus.IN_PROGRESS);

        SessionParticipantPowerCard assignment = powerCardAssignmentRepository.findByIdAndSessionId(assignmentId, sessionId)
            .orElseThrow(() -> ApiException.notFound("POWER_CARD_NOT_FOUND", "Power card assignment not found"));

        if (assignment.isUsed()) {
            throw ApiException.conflict("POWER_CARD_ALREADY_USED", "This power card has already been used this session");
        }

        SessionCard currentCard = sessionCardRepository.findBySessionIdAndStatus(sessionId, SessionCardStatus.DRAWN)
            .orElseThrow(() -> ApiException.conflict("NO_ACTIVE_CARD", "No card is currently active for this session"));

        SessionParticipant target = null;
        if (targetParticipantId != null) {
            target = participantRepository.findById(targetParticipantId)
                .filter(p -> p.getSession().getId().equals(sessionId))
                .orElseThrow(() -> ApiException.notFound("PARTICIPANT_NOT_FOUND", "Target participant not found in this session"));
        }

        assignment.setUsedAt(Instant.now());
        assignment.setUsedOnSessionCard(currentCard);
        assignment.setTargetParticipant(target);
        powerCardAssignmentRepository.save(assignment);

        PowerCardEffect effect = assignment.getPowerCardDefinition().getEffectType();
        if (effect == PowerCardEffect.CHANGE_QUESTION) {
            return replaceCurrentCard(sessionId, currentCard.getId());
        }
        if (effect == PowerCardEffect.DECLINE_TO_ANSWER) {
            return skipCurrentCard(sessionId, currentCard.getId());
        }

        return broadcastAndReturn(session);
    }

    @Transactional
    public SessionStateResponse awardScore(UUID sessionId, UUID participantId, int points, String reasonCode, String note) {
        GameSession session = requireSession(sessionId);
        requireStatus(session, SessionStatus.IN_PROGRESS);

        SessionParticipant participant = participantRepository.findById(participantId)
            .filter(p -> p.getSession().getId().equals(sessionId))
            .orElseThrow(() -> ApiException.notFound("PARTICIPANT_NOT_FOUND", "Participant not found in this session"));

        SessionCard currentCard = sessionCardRepository.findBySessionIdAndStatus(sessionId, SessionCardStatus.DRAWN).orElse(null);

        scoreEventRepository.save(new ScoreEvent(session, currentCard, participant, points, reasonCode, note));
        participant.setScore(participant.getScore() + points);
        participantRepository.save(participant);

        return broadcastAndReturn(session);
    }

    @Transactional
    public SessionStateResponse pause(UUID sessionId) {
        GameSession session = requireSession(sessionId);
        requireStatus(session, SessionStatus.IN_PROGRESS);
        session.setStatus(SessionStatus.PAUSED);
        session.setPausedAt(Instant.now());
        return broadcastAndReturn(gameSessionRepository.saveAndFlush(session));
    }

    @Transactional
    public SessionStateResponse resume(UUID sessionId) {
        GameSession session = requireSession(sessionId);
        requireStatus(session, SessionStatus.PAUSED);
        session.setStatus(SessionStatus.IN_PROGRESS);
        session.setPausedAt(null);
        return broadcastAndReturn(gameSessionRepository.saveAndFlush(session));
    }

    @Transactional
    public SessionStateResponse cancel(UUID sessionId) {
        GameSession session = requireSession(sessionId);
        if (session.getStatus() == SessionStatus.COMPLETED || session.getStatus() == SessionStatus.CANCELLED) {
            throw ApiException.conflict("INVALID_STATE", "Session already finished");
        }
        session.setStatus(SessionStatus.CANCELLED);
        return broadcastAndReturn(gameSessionRepository.saveAndFlush(session));
    }

    private SessionStateResponse replaceCurrentCard(UUID sessionId, UUID sessionCardId) {
        GameSession session = requireSession(sessionId);
        SessionCard card = requireDrawnCard(session, sessionCardId);

        card.setStatus(SessionCardStatus.REPLACED);
        card.setCompletedAt(Instant.now());
        sessionCardRepository.save(card);
        trashCard(session, card);

        List<SessionCard> allSessionCards = sessionCardRepository.findBySessionIdOrderByDrawOrderAsc(sessionId);
        List<UUID> usedCardIds = allSessionCards.stream().map(sc -> sc.getCard().getId()).toList();
        List<UUID> excluded = new ArrayList<>(cardTrashRepository.findActiveTrashedCardIds(session.getGroup().getId()));
        excluded.addAll(usedCardIds);

        String effectiveCategory = session.getGameMode() == GameMode.CATEGORY ? session.getCategoryCode() : null;
        boolean bestOnly = session.getGameMode() == GameMode.BEST_CARDS;
        String activePlayerPublicId = card.getActivePlayer().getUser().getPublicId();
        List<Card> pool = cardRepository.findEligibleCards(excluded, null, effectiveCategory, bestOnly).stream()
            .filter(c -> c.getEligiblePlayerPublicIds().contains(activePlayerPublicId))
            .toList();

        if (pool.isEmpty()) {
            throw ApiException.conflict("NO_REPLACEMENT_CARD", "No eligible cards left to draw as a replacement");
        }

        Card replacement = pool.get(secureRandom.nextInt(pool.size()));
        int nextDrawOrder = allSessionCards.stream().mapToInt(SessionCard::getDrawOrder).max().orElse(-1) + 1;

        SessionCard replacementCard = new SessionCard(session, replacement, nextDrawOrder);
        replacementCard.setStatus(SessionCardStatus.DRAWN);
        replacementCard.setDrawnAt(Instant.now());
        replacementCard.setActivePlayer(card.getActivePlayer());
        sessionCardRepository.save(replacementCard);

        return broadcastAndReturn(gameSessionRepository.saveAndFlush(session));
    }

    private void advanceTurn(GameSession session) {
        List<SessionParticipant> participants = participantRepository.findBySessionIdOrderByTurnPositionAsc(session.getId());
        int currentPos = session.getCurrentTurnPosition() != null ? session.getCurrentTurnPosition() : 0;
        int nextPos = (currentPos + 1) % participants.size();
        session.setCurrentTurnPosition(nextPos);
        session.setCompletedCardCount(session.getCompletedCardCount() + 1);

        if (session.getCompletedCardCount() >= session.getRequestedCardCount()) {
            session.setStatus(SessionStatus.COMPLETED);
            session.setCompletedAt(Instant.now());
            return;
        }

        SessionParticipant nextPlayer = participants.get(nextPos);
        sessionCardRepository.findFirstBySessionIdAndStatusOrderByDrawOrderAsc(session.getId(), SessionCardStatus.PENDING)
            .ifPresentOrElse(
                nextCard -> {
                    nextCard.setStatus(SessionCardStatus.DRAWN);
                    nextCard.setDrawnAt(Instant.now());
                    nextCard.setActivePlayer(nextPlayer);
                    sessionCardRepository.save(nextCard);
                },
                () -> {
                    session.setStatus(SessionStatus.COMPLETED);
                    session.setCompletedAt(Instant.now());
                }
            );
    }

    private void requireEveryoneHasChosenPowerCards(GameSession session, List<SessionParticipant> participants) {
        int requiredCount = gameSettingsService.getSettings().getPowerCardsPerPlayer();
        if (requiredCount == 0) {
            return;
        }

        Map<UUID, Long> countsByParticipant = powerCardAssignmentRepository.findBySessionId(session.getId()).stream()
            .collect(Collectors.groupingBy(pc -> pc.getParticipant().getId(), Collectors.counting()));

        List<String> missing = participants.stream()
            .filter(p -> countsByParticipant.getOrDefault(p.getId(), 0L) != requiredCount)
            .map(p -> p.getUser().getDisplayName())
            .toList();

        if (!missing.isEmpty()) {
            throw ApiException.conflict(
                "POWER_CARDS_NOT_CHOSEN",
                "These players still need to choose their power cards: " + String.join(", ", missing)
            );
        }
    }

    private boolean everyoneHasChosenPowerCards(GameSession session, List<SessionParticipant> participants, int requiredCount) {
        Map<UUID, Long> countsByParticipant = powerCardAssignmentRepository.findBySessionId(session.getId()).stream()
            .collect(Collectors.groupingBy(pc -> pc.getParticipant().getId(), Collectors.counting()));

        return participants.stream()
            .allMatch(p -> countsByParticipant.getOrDefault(p.getId(), 0L) == requiredCount);
    }

    private void trashCard(GameSession session, SessionCard sessionCard) {
        cardTrashRepository.save(new CardTrash(session.getGroup(), sessionCard.getCard(), session));
    }

    private void addParticipantInternal(GameSession session, AppUser user, boolean joinedViaCode) {
        int nextPosition = (int) participantRepository.countBySessionId(session.getId());
        SessionParticipant participant = new SessionParticipant(session, user, nextPosition);
        participant.setJoinedViaCode(joinedViaCode);
        participantRepository.save(participant);

        // The newcomer hasn't chosen their power cards yet; a session that had
        // already reached READY needs to go back to waiting for them.
        if (session.getStatus() == SessionStatus.READY) {
            session.setStatus(SessionStatus.WAITING_FOR_PLAYERS);
            gameSessionRepository.saveAndFlush(session);
        }
    }

    private void requireGroupMember(UUID groupId, UUID userId) {
        boolean isMember = groupMemberRepository.findByUserId(userId).stream()
            .anyMatch(gm -> gm.getGroup().getId().equals(groupId));
        if (!isMember) {
            throw ApiException.forbidden("NOT_GROUP_MEMBER", "You are not a member of this group");
        }
    }

    private void validatePoolSize(GameGroup group, GameMode mode, String categoryCode, int requestedCardCount) {
        List<UUID> trashedIds = cardTrashRepository.findActiveTrashedCardIds(group.getId());
        String effectiveCategory = mode == GameMode.CATEGORY ? categoryCode : null;
        boolean bestOnly = mode == GameMode.BEST_CARDS;
        List<Card> pool = cardRepository.findEligibleCards(trashedIds, null, effectiveCategory, bestOnly);

        if (pool.isEmpty()) {
            throw ApiException.conflict("NO_ELIGIBLE_CARDS", "No eligible cards remain for this mode");
        }
        if (pool.size() < requestedCardCount) {
            throw ApiException.conflict(
                "NOT_ENOUGH_CARDS",
                "Only " + pool.size() + " eligible cards remain; lower the requested count or restore cards from the trash"
            );
        }
    }

    /**
     * Builds the actual N-card draw order for a session about to start. Turn
     * order is a fixed round-robin from {@code startingIndex}, so which
     * participant is active at each slot is already fully determined; each
     * slot gets the first not-yet-used card (from a seed-shuffled pool) whose
     * {@code eligiblePlayerPublicIds} contains that slot's active participant.
     */
    private List<Card> buildEligibleSequence(GameSession session, List<SessionParticipant> participants, int startingIndex) {
        List<UUID> trashedIds = cardTrashRepository.findActiveTrashedCardIds(session.getGroup().getId());
        String effectiveCategory = session.getGameMode() == GameMode.CATEGORY ? session.getCategoryCode() : null;
        boolean bestOnly = session.getGameMode() == GameMode.BEST_CARDS;
        List<Card> pool = cardRepository.findEligibleCards(trashedIds, null, effectiveCategory, bestOnly);

        List<Card> shuffled = new ArrayList<>(pool);
        Collections.shuffle(shuffled, new Random(session.getRandomSeed()));

        int requestedCardCount = session.getRequestedCardCount();
        List<Card> result = new ArrayList<>(requestedCardCount);
        Set<UUID> used = new HashSet<>();

        for (int i = 0; i < requestedCardCount; i++) {
            SessionParticipant activePlayer = participants.get((startingIndex + i) % participants.size());
            String publicId = activePlayer.getUser().getPublicId();

            Card chosen = shuffled.stream()
                .filter(c -> !used.contains(c.getId()))
                .filter(c -> c.getEligiblePlayerPublicIds().contains(publicId))
                .findFirst()
                .orElseThrow(() -> ApiException.conflict(
                    "NOT_ENOUGH_ELIGIBLE_CARDS",
                    "Not enough eligible cards remain for " + activePlayer.getUser().getDisplayName()
                ));

            result.add(chosen);
            used.add(chosen.getId());
        }

        return result;
    }

    private String generateUniqueSessionCode() {
        String code;
        do {
            StringBuilder builder = new StringBuilder(SESSION_CODE_LENGTH);
            for (int i = 0; i < SESSION_CODE_LENGTH; i++) {
                builder.append(CODE_ALPHABET.charAt(secureRandom.nextInt(CODE_ALPHABET.length())));
            }
            code = builder.toString();
        } while (gameSessionRepository.existsBySessionCode(code));
        return code;
    }

    private GameMode parseGameMode(String value) {
        try {
            return GameMode.valueOf(value);
        } catch (IllegalArgumentException e) {
            throw ApiException.badRequest("INVALID_GAME_MODE", "Unknown game mode: " + value);
        }
    }

    private GameSession requireSession(UUID id) {
        return gameSessionRepository.findById(id)
            .orElseThrow(() -> ApiException.notFound("SESSION_NOT_FOUND", "Session not found"));
    }

    private GameSession requireSessionByCode(String sessionCode) {
        return gameSessionRepository.findBySessionCode(sessionCode.trim().toUpperCase())
            .orElseThrow(() -> ApiException.notFound("SESSION_NOT_FOUND", "No session with that code"));
    }

    private void requireStatus(GameSession session, SessionStatus expected) {
        if (session.getStatus() != expected) {
            throw ApiException.conflict("INVALID_STATE", "Expected status " + expected + " but was " + session.getStatus());
        }
    }

    private SessionCard requireDrawnCard(GameSession session, UUID sessionCardId) {
        SessionCard drawn = sessionCardRepository.findBySessionIdAndStatus(session.getId(), SessionCardStatus.DRAWN)
            .orElseThrow(() -> ApiException.conflict("NO_ACTIVE_CARD", "No card is currently active for this session"));
        if (!drawn.getId().equals(sessionCardId)) {
            throw ApiException.conflict("STALE_CARD", "This card is no longer the active one; refresh session state");
        }
        return drawn;
    }

    private SessionStateResponse broadcastAndReturn(GameSession session) {
        SessionStateResponse response = toStateResponse(session);
        sessionSocketHandler.broadcast(session.getSessionCode(), "SESSION_UPDATED", response);
        return response;
    }

    private SessionStateResponse toStateResponse(GameSession session) {
        List<SessionParticipant> participants = participantRepository.findBySessionIdOrderByTurnPositionAsc(session.getId());
        Map<UUID, List<SessionParticipantPowerCard>> powerCardsByParticipant = powerCardAssignmentRepository
            .findBySessionId(session.getId()).stream()
            .collect(Collectors.groupingBy(pc -> pc.getParticipant().getId()));

        List<ParticipantResponse> participantResponses = participants.stream()
            .sorted(Comparator.comparingInt(SessionParticipant::getTurnPosition))
            .map(p -> new ParticipantResponse(
                p.getId(),
                p.getUser().getId(),
                p.getUser().getPublicId(),
                p.getUser().getDisplayName(),
                p.getTurnPosition(),
                p.getScore(),
                session.getCurrentTurnPosition() != null && session.getCurrentTurnPosition() == p.getTurnPosition(),
                p.isJoinedViaCode(),
                powerCardsByParticipant.getOrDefault(p.getId(), List.of()).stream()
                    .map(pc -> new PowerCardAssignmentResponse(
                        pc.getId(),
                        pc.getPowerCardDefinition().getCode(),
                        pc.getPowerCardDefinition().getTitle(),
                        pc.getPowerCardDefinition().getDescription(),
                        pc.isUsed(),
                        pc.getTargetParticipant() != null ? pc.getTargetParticipant().getId() : null
                    ))
                    .toList()
            ))
            .toList();

        CurrentCardResponse currentCard = sessionCardRepository
            .findBySessionIdAndStatus(session.getId(), SessionCardStatus.DRAWN)
            .map(sc -> {
                CardTranslation translation = cardTranslationRepository
                    .findByCardIdAndLanguageCode(sc.getCard().getId(), DEFAULT_LANGUAGE)
                    .orElse(null);
                return new CurrentCardResponse(
                    sc.getId(),
                    sc.getCard().getId(),
                    sc.getCard().getCardType().name(),
                    sc.getCard().getCategory() != null ? sc.getCard().getCategory().getCode() : null,
                    translation != null ? translation.getTitle() : null,
                    translation != null ? translation.getText() : null,
                    translation != null ? translation.getInstructions() : null,
                    sc.getCard().getAnswerMode(),
                    sc.getCard().getTimerSeconds(),
                    sc.getCard().isSkippable(),
                    sc.getCard().isSupportsScoring(),
                    sc.getActivePlayer() != null ? sc.getActivePlayer().getId() : null
                );
            })
            .orElse(null);

        return new SessionStateResponse(
            session.getId(),
            session.getSessionCode(),
            session.getStatus().name(),
            session.getGameMode().name(),
            session.getCategoryCode(),
            session.isScoringEnabled(),
            session.getRequestedCardCount(),
            session.getCompletedCardCount(),
            participantResponses,
            currentCard,
            session.getStartedAt(),
            session.getPausedAt(),
            session.getCompletedAt(),
            session.getVersion()
        );
    }
}
