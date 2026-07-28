package tn.itvision.betweenthree.identity.service;

import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.core.annotation.Order;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import lombok.extern.slf4j.Slf4j;
import tn.itvision.betweenthree.identity.config.UserSeedProperties;
import tn.itvision.betweenthree.identity.domain.AppUser;
import tn.itvision.betweenthree.identity.domain.UserRole;
import tn.itvision.betweenthree.identity.repository.AppUserRepository;

/**
 * Seeds the private family's player profiles on first boot. This app has no
 * self-registration in v0 (see architecture decision: seed process instead of
 * an admin UI) — accounts are provisioned once via {@code app.seed.players}.
 */
@Slf4j
@Component
@Order(1)
@EnableConfigurationProperties(UserSeedProperties.class)
public class AppUserSeedService implements ApplicationRunner {

    private final AppUserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final UserSeedProperties seedProperties;

    public AppUserSeedService(
        AppUserRepository userRepository,
        PasswordEncoder passwordEncoder,
        UserSeedProperties seedProperties
    ) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.seedProperties = seedProperties;
    }

    @Override
    public void run(ApplicationArguments args) {
        if (!seedProperties.enabled() || seedProperties.players() == null) {
            return;
        }

        for (UserSeedProperties.SeedPlayer player : seedProperties.players()) {
            if (userRepository.existsByPublicId(player.publicId())) {
                continue;
            }

            AppUser user = new AppUser(
                player.publicId(),
                player.displayName(),
                passwordEncoder.encode(player.pin()),
                UserRole.valueOf(player.role())
            );
            userRepository.save(user);
            log.info("Seeded player profile '{}' ({})", player.publicId(), player.displayName());
        }
    }
}
