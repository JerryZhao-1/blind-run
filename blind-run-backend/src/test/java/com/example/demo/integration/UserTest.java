package com.example.demo.integration;

import com.fasterxml.jackson.databind.JsonNode;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.time.LocalDateTime;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * 用户模块集成测试（TC-USER-01 ~ 09）
 */
class UserTest extends BaseIntegrationTest {

    // ==================== 角色设置 ====================

    /** TC-USER-01：设置角色 BLIND 成功 */
    @Test
    @DisplayName("TC-USER-01: 设置角色 BLIND 成功")
    void tc01_setRoleBlind() {
        String token = testHelper.registerAndLogin("13800020001");

        ResponseEntity<String> response = restTemplate.postForEntity(
                "/api/user/role", testHelper.jsonEntity(token, "{\"role\":\"BLIND\"}"), String.class);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        JsonNode json = testHelper.extractJson(response.getBody());
        assertThat(json.get("success").asBoolean()).isTrue();
        assertThat(json.get("role").asText()).isEqualTo("BLIND");

        System.out.println("✅ TC-USER-01 passed — 设置角色 BLIND 成功");
    }

    /** TC-USER-02：设置角色 VOLUNTEER 成功 */
    @Test
    @DisplayName("TC-USER-02: 设置角色 VOLUNTEER 成功")
    void tc02_setRoleVolunteer() {
        String token = testHelper.registerAndLogin("13800020002");

        ResponseEntity<String> response = restTemplate.postForEntity(
                "/api/user/role", testHelper.jsonEntity(token, "{\"role\":\"VOLUNTEER\"}"), String.class);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        JsonNode json = testHelper.extractJson(response.getBody());
        assertThat(json.get("success").asBoolean()).isTrue();
        assertThat(json.get("role").asText()).isEqualTo("VOLUNTEER");

        System.out.println("✅ TC-USER-02 passed — 设置角色 VOLUNTEER 成功");
    }

    /** TC-USER-03：角色已设定时再次设置返回 409 */
    @Test
    @DisplayName("TC-USER-03: 角色已设定冲突")
    void tc03_roleAlreadySet() {
        String token = testHelper.registerAndLoginWithRole("13800020003", "BLIND");

        ResponseEntity<String> response = restTemplate.postForEntity(
                "/api/user/role", testHelper.jsonEntity(token, "{\"role\":\"VOLUNTEER\"}"), String.class);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CONFLICT);
        JsonNode json = testHelper.extractJson(response.getBody());
        assertThat(json.get("success").asBoolean()).isFalse();
        assertThat(json.get("code").asInt()).isEqualTo(409);
        assertThat(json.get("message").asText()).isNotEmpty();

        System.out.println("✅ TC-USER-03 passed — 角色已设定冲突");
    }

    /** TC-USER-04：无效角色（空 body）返回 400 */
    @Test
    @DisplayName("TC-USER-04: 无效角色（空 body）返回 400")
    void tc04_invalidRole() {
        String token = testHelper.registerAndLogin("13800020004");

        ResponseEntity<String> response = restTemplate.postForEntity(
                "/api/user/role", testHelper.jsonEntity(token, "{}"), String.class);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);

        System.out.println("✅ TC-USER-04 passed — 无效角色（空 body）返回 400");
    }

    // ==================== 用户信息 ====================

    /** TC-USER-05：获取自己的用户信息，手机号脱敏 */
    @Test
    @DisplayName("TC-USER-05: 获取自己的用户信息")
    void tc05_getOwnUserInfo() {
        String token = testHelper.registerAndLoginWithRole("13800020005", "BLIND");
        Long userId = testHelper.extractUserId(token);

        ResponseEntity<String> response = testHelper.getUserInfo(token, userId);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        JsonNode json = testHelper.extractJson(response.getBody());
        assertThat(json.get("userId").asLong()).isEqualTo(userId);
        // 手机号脱敏：前3位 + **** + 后4位
        assertThat(json.get("phone").asText()).matches("\\d{3}\\*{4}\\d{4}");
        assertThat(json.get("role").asText()).isEqualTo("BLIND");
        assertThat(json.has("createdAt")).isTrue();

        System.out.println("✅ TC-USER-05 passed — 获取自己的用户信息");
    }

    /** TC-USER-06：获取其他用户信息返回 403 */
    @Test
    @DisplayName("TC-USER-06: 获取其他用户信息返回 403")
    void tc06_getOtherUserInfo() {
        String tokenA = testHelper.registerAndLoginWithRole("13800020006", "BLIND");
        String tokenB = testHelper.registerAndLoginWithRole("13800020007", "BLIND");
        Long userIdB = testHelper.extractUserId(tokenB);

        // A 尝试获取 B 的信息
        ResponseEntity<String> response = testHelper.getUserInfo(tokenA, userIdB);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN);
        JsonNode json = testHelper.extractJson(response.getBody());
        assertThat(json.get("success").asBoolean()).isFalse();
        assertThat(json.get("code").asInt()).isEqualTo(403);

        System.out.println("✅ TC-USER-06 passed — 获取其他用户信息返回 403");
    }

    // ==================== 注销账号 ====================

    /** TC-USER-07：注销账号成功 */
    @Test
    @DisplayName("TC-USER-07: 注销账号成功")
    void tc07_deleteAccountSuccess() {
        String token = testHelper.registerAndLoginWithRole("13800020008", "BLIND");
        Long userId = testHelper.extractUserId(token);

        ResponseEntity<String> response = testHelper.deleteUser(token, userId);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        JsonNode json = testHelper.extractJson(response.getBody());
        assertThat(json.get("success").asBoolean()).isTrue();

        System.out.println("✅ TC-USER-07 passed — 注销账号成功");
    }

    /** TC-USER-08：有进行中的订单时注销返回 409 */
    @Test
    @DisplayName("TC-USER-08: 有进行中的订单时注销返回 409")
    void tc08_deleteWithActiveOrder() {
        // 盲人用户创建订单
        String blindToken = testHelper.registerAndLoginWithRole("13800020009", "BLIND");
        Long blindUserId = testHelper.extractUserId(blindToken);

        // 志愿者上线
        String volToken = testHelper.registerAndLoginWithRole("13800020010", "VOLUNTEER");
        testHelper.updateVolunteerLocation(volToken, 39.9242, 116.4677, true);

        // 创建订单（PENDING_MATCH → 异步匹配 → PENDING_ACCEPT → 接单 → IN_PROGRESS）
        Long orderId = testHelper.createOrder(blindToken, 39.9042, 116.4674, "朝阳公园南门",
                LocalDateTime.now().plusHours(1), LocalDateTime.now().plusHours(2));

        // 等待匹配完成后志愿者接单
        try {
            testHelper.waitForOrderStatus(blindToken, orderId,
                    com.example.demo.entity.OrderStatus.PENDING_ACCEPT, 5);
            testHelper.acceptOrder(volToken, orderId);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }

        // 盲人有进行中的订单，尝试注销
        ResponseEntity<String> response = testHelper.deleteUser(blindToken, blindUserId);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CONFLICT);
        JsonNode json = testHelper.extractJson(response.getBody());
        assertThat(json.get("success").asBoolean()).isFalse();
        assertThat(json.get("code").asInt()).isEqualTo(409);

        System.out.println("✅ TC-USER-08 passed — 有进行中的订单时注销返回 409");
    }

    /** TC-USER-09：注销其他用户返回 403 */
    @Test
    @DisplayName("TC-USER-09: 注销其他用户返回 403")
    void tc09_deleteOtherUser() {
        String tokenA = testHelper.registerAndLoginWithRole("13800020011", "BLIND");
        String tokenB = testHelper.registerAndLoginWithRole("13800020012", "BLIND");
        Long userIdB = testHelper.extractUserId(tokenB);

        // A 尝试注销 B 的账号
        ResponseEntity<String> response = testHelper.deleteUser(tokenA, userIdB);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN);
        JsonNode json = testHelper.extractJson(response.getBody());
        assertThat(json.get("success").asBoolean()).isFalse();
        assertThat(json.get("code").asInt()).isEqualTo(403);

        System.out.println("✅ TC-USER-09 passed — 注销其他用户返回 403");
    }
}
