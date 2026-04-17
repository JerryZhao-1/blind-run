package com.example.demo.integration;

import com.example.demo.repository.VolunteerProfileRepository;
import com.example.demo.service.VerificationCodeService;
import org.junit.jupiter.api.BeforeEach;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.context.jdbc.Sql;
import org.testcontainers.containers.GenericContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.utility.DockerImageName;

/**
 * 集成测试基类 —— 所有集成测试继承此类
 *
 * 使用 Testcontainers 启动真实 Redis 容器，
 * VolunteerLocationService 可正常使用 Redis 缓存。
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
@Testcontainers
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_CLASS)
@Sql(scripts = "/sql/cleanup.sql", executionPhase = Sql.ExecutionPhase.BEFORE_TEST_METHOD)
public abstract class BaseIntegrationTest {

    @Container
    static GenericContainer<?> redis = new GenericContainer<>(DockerImageName.parse("redis:7-alpine"))
            .withExposedPorts(6379);

    @DynamicPropertySource
    static void redisProps(DynamicPropertyRegistry registry) {
        registry.add("spring.data.redis.host", redis::getHost);
        registry.add("spring.data.redis.port", () -> redis.getMappedPort(6379));
    }

    @Autowired
    protected TestRestTemplate restTemplate;

    @LocalServerPort
    protected int port;

    @Autowired
    protected VerificationCodeService verificationCodeService;

    @Autowired
    protected StringRedisTemplate redisTemplate;

    @Autowired
    protected VolunteerProfileRepository volunteerProfileRepository;

    protected TestHelper testHelper;

    @BeforeEach
    void setupBase() {
        // 清理 Redis 志愿者位置缓存，与 @Sql DB 清理同步
        cleanupVolunteerLocations();
        testHelper = new TestHelper(restTemplate, verificationCodeService, volunteerProfileRepository);
    }

    private void cleanupVolunteerLocations() {
        try {
            var keys = redisTemplate.keys("vol:loc:*");
            if (keys != null && !keys.isEmpty()) {
                redisTemplate.delete(keys);
            }
        } catch (Exception e) {
            System.err.println("Redis 清理失败: " + e.getMessage());
        }
    }
}
