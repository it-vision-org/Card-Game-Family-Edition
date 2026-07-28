package tn.itvision.betweenthree.sessions;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.List;
import java.util.UUID;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import tn.itvision.betweenthree.common.api.ApiException;
import tn.itvision.betweenthree.content.domain.PowerCardDefinition;
import tn.itvision.betweenthree.content.repository.PowerCardDefinitionRepository;
import tn.itvision.betweenthree.groups.domain.GameGroup;
import tn.itvision.betweenthree.groups.service.GroupService;
import tn.itvision.betweenthree.identity.domain.AppUser;
import tn.itvision.betweenthree.identity.repository.AppUserRepository;
import tn.itvision.betweenthree.sessions.api.dto.SessionStateResponse;
import tn.itvision.betweenthree.sessions.repository.CardTrashRepository;
import tn.itvision.betweenthree.sessions.service.SessionService;
import tn.itvision.betweenthree.support.IntegrationTestSupport;

class SessionLifecycleIntegrationTest extends IntegrationTestSupport {

    @Autowired
    private AppUserRepository userRepository;

    @Autowired
    private GroupService groupService;

    @Autowired
    private SessionService sessionService;

    @Autowired
    private CardTrashRepository cardTrashRepository;

    @Autowired
    private PowerCardDefinitionRepository powerCardDefinitionRepository;

    @Test
    void fullLifecycle_completesSessionAndNeverReusesTrashedCards() {
        AppUser ahmed = userRepository.findByPublicId("AHMED").orElseThrow();
        AppUser rahma = userRepository.findByPublicId("RAHMA").orElseThrow();
        AppUser mamti = userRepository.findByPublicId("MAMTI").orElseThrow();

        UUID powerCardDefinitionId = powerCardDefinitionRepository.findByActiveTrue().get(0).getId();

        GameGroup group = groupService.listGroupsForUser(ahmed.getId()).get(0);

        SessionStateResponse created = sessionService.createSession(group.getId(), ahmed, "MIXED", null, 3, true);
        assertThat(created.status()).isEqualTo("WAITING_FOR_PLAYERS");
        assertThat(created.participants()).hasSize(1);

        sessionService.joinByCode(created.sessionCode(), rahma);
        SessionStateResponse joined = sessionService.joinByCode(created.sessionCode(), mamti);
        assertThat(joined.participants()).hasSize(3);

        // Starting before everyone has chosen their power cards must be rejected.
        assertThatThrownBy(() -> sessionService.start(created.id()))
            .isInstanceOf(ApiException.class)
            .hasFieldOrPropertyWithValue("code", "POWER_CARDS_NOT_CHOSEN");

        // Each player picks a hand of 2 (the default game_settings value) — the
        // same power card chosen twice, proving duplicates are now allowed
        // (this used to be blocked by a unique constraint).
        SessionStateResponse afterPicks = null;
        for (var participant : joined.participants()) {
            afterPicks = sessionService.choosePowerCards(
                created.id(),
                participant.id(),
                List.of(powerCardDefinitionId, powerCardDefinitionId)
            );
        }
        assertThat(afterPicks.status()).isEqualTo("READY");
        assertThat(afterPicks.participants()).allSatisfy(p -> assertThat(p.powerCards()).hasSize(2));

        SessionStateResponse started = sessionService.start(created.id());
        assertThat(started.status()).isEqualTo("IN_PROGRESS");
        assertThat(started.currentCard()).isNotNull();
        assertThat(started.participants())
            .allSatisfy(p -> assertThat(p.powerCards()).hasSize(2));

        UUID firstCardId = started.currentCard().cardId();
        SessionStateResponse afterFirst = sessionService.completeCurrentCard(created.id(), started.currentCard().sessionCardId());
        assertThat(afterFirst.completedCardCount()).isEqualTo(1);
        assertThat(afterFirst.currentCard()).isNotNull();

        List<UUID> trashedAfterFirst = cardTrashRepository.findActiveTrashedCardIds(group.getId());
        assertThat(trashedAfterFirst).contains(firstCardId);

        SessionStateResponse afterSecond = sessionService.completeCurrentCard(created.id(), afterFirst.currentCard().sessionCardId());
        assertThat(afterSecond.completedCardCount()).isEqualTo(2);
        assertThat(afterSecond.currentCard()).isNotNull();

        SessionStateResponse afterThird = sessionService.completeCurrentCard(created.id(), afterSecond.currentCard().sessionCardId());
        assertThat(afterThird.completedCardCount()).isEqualTo(3);
        assertThat(afterThird.status()).isEqualTo("COMPLETED");
        assertThat(afterThird.currentCard()).isNull();

        List<UUID> trashedIds = cardTrashRepository.findActiveTrashedCardIds(group.getId());
        assertThat(trashedIds).hasSize(3);

        SessionStateResponse secondSession = sessionService.createSession(group.getId(), rahma, "MIXED", null, 1, false);
        SessionStateResponse secondJoined = sessionService.joinByCode(secondSession.sessionCode(), ahmed);
        secondJoined = sessionService.joinByCode(secondSession.sessionCode(), mamti);
        for (var participant : secondJoined.participants()) {
            sessionService.choosePowerCards(
                secondSession.id(),
                participant.id(),
                List.of(powerCardDefinitionId, powerCardDefinitionId)
            );
        }
        SessionStateResponse secondStarted = sessionService.start(secondSession.id());

        assertThat(trashedIds).doesNotContain(secondStarted.currentCard().cardId());
    }
}
