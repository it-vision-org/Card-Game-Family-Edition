package tn.itvision.betweenthree.support;

import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.PostgreSQLContainer;

/**
 * Base for tests that need the real schema/enums/JSON columns applied by
 * Flyway against a real PostgreSQL instance, rather than an in-memory
 * substitute that would hide native-enum/JSONB mapping mistakes.
 *
 * <p>The container is started once, manually, and deliberately never stopped
 * ("singleton container" pattern) so it survives across every test class that
 * extends this base — letting Spring's test context cache be reused too.
 * Testcontainers' Ryuk reaper removes it when the JVM/test run ends.
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
public abstract class IntegrationTestSupport {

    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:17");

    static {
        POSTGRES.start();
    }

    @DynamicPropertySource
    static void datasourceProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", POSTGRES::getJdbcUrl);
        registry.add("spring.datasource.username", POSTGRES::getUsername);
        registry.add("spring.datasource.password", POSTGRES::getPassword);
    }
}
