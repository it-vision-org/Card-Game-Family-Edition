package tn.itvision.betweenthree.groups.service;

import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import lombok.extern.slf4j.Slf4j;
import tn.itvision.betweenthree.groups.domain.GameGroup;
import tn.itvision.betweenthree.groups.domain.RelationshipType;
import tn.itvision.betweenthree.groups.repository.GameGroupRepository;
import tn.itvision.betweenthree.identity.repository.AppUserRepository;

/**
 * Seeds the single family group for the three private v0 players, with their
 * relationships already wired up, so the app is playable right after startup
 * with no manual setup step. Runs after {@link tn.itvision.betweenthree.identity.service.AppUserSeedService}.
 */
@Slf4j
@Component
@Order(2)
public class GroupSeedService implements ApplicationRunner {

    private static final String FAMILY_GROUP_NAME = "بيناتنا الثلاثة";

    private final AppUserRepository userRepository;
    private final GameGroupRepository groupRepository;
    private final GroupService groupService;

    public GroupSeedService(AppUserRepository userRepository, GameGroupRepository groupRepository, GroupService groupService) {
        this.userRepository = userRepository;
        this.groupRepository = groupRepository;
        this.groupService = groupService;
    }

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        if (!groupRepository.findAll().isEmpty()) {
            return;
        }

        var ahmed = userRepository.findByPublicId("AHMED").orElse(null);
        var rahma = userRepository.findByPublicId("RAHMA").orElse(null);
        var mamti = userRepository.findByPublicId("MAMTI").orElse(null);

        if (ahmed == null || rahma == null || mamti == null) {
            return;
        }

        GameGroup group = groupService.createGroup(FAMILY_GROUP_NAME, ahmed);
        groupService.addMember(group.getId(), rahma.getPublicId());
        groupService.addMember(group.getId(), mamti.getPublicId());

        groupService.defineRelationship(group.getId(), ahmed.getPublicId(), rahma.getPublicId(), RelationshipType.PARTNER);
        groupService.defineRelationship(group.getId(), ahmed.getPublicId(), mamti.getPublicId(), RelationshipType.PARTNER_PARENT);
        groupService.defineRelationship(group.getId(), rahma.getPublicId(), mamti.getPublicId(), RelationshipType.PARENT_CHILD);

        log.info("Seeded family group '{}' with members Ahmed, Rahma, Mamti", FAMILY_GROUP_NAME);
    }
}
