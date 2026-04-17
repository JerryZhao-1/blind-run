package com.example.demo.integration;

import com.fasterxml.jackson.databind.JsonNode;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * 订单权限测试（TC-PERM-01 ~ 07）
 *
 * 验证订单各操作的场景权限控制：
 * 未登录、第三方无关用户、盲人接单、未认证志愿者、重复接单、重复下单
 */
class OrderPermissionTest extends BaseIntegrationTest {

    // ==================== TC-PERM-01 ====================

    /** TC-PERM-01：无 token 创建订单 → 401 */
    @Test
    @DisplayName("TC-PERM-01: 无token创建订单返回401")
    void tcPerm01_noTokenCreateOrder_returns401() {
        ResponseEntity<String> response = testHelper.createOrderRaw(null, """
                {"startLatitude":39.9,"startLongitude":116.4,"startAddress":"测试地址",
                 "plannedStartTime":"2099-06-01T18:00:00","plannedEndTime":"2099-06-01T19:00:00"}
                """);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
        System.out.println("✅ TC-PERM-01 passed — 无token创建订单返回401");
    }

    // ==================== TC-PERM-02 ====================

    /** TC-PERM-02：第三方无关用户查看他人订单 → 403 */
    @Test
    @DisplayName("TC-PERM-02: 第三方用户查看他人订单返回403")
    void tcPerm02_strangerViewOrder_returns403() throws Exception {
        // 用户 A（盲人）创建订单
        String blindToken = testHelper.registerAndLoginWithRole("13800070001", "BLIND");
        // 用户 B（志愿者）接单
        String volToken = testHelper.registerAndLoginWithRole("13800070002", "VOLUNTEER");
        testHelper.updateVolunteerLocation(volToken, 39.9242, 116.4677, true);

        Long orderId = testHelper.createOrder(blindToken, 39.9042, 116.4674, "朝阳公园南门",
                TestHelper.defaultStartTime(), TestHelper.defaultEndTime());

        testHelper.waitForOrderStatus(blindToken, orderId,
                com.example.demo.entity.OrderStatus.PENDING_ACCEPT, 5);
        testHelper.acceptOrder(volToken, orderId);

        // 用户 C（陌生人）尝试查看 A+B 的订单
        String strangerToken = testHelper.registerAndLogin("13800070003");
        ResponseEntity<String> response = testHelper.getOrder(strangerToken, orderId);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN);
        JsonNode json = testHelper.extractJson(response.getBody());
        assertThat(json.get("success").asBoolean()).isFalse();
        assertThat(json.get("code").asInt()).isEqualTo(403);
        assertThat(json.get("message").asText()).contains("无权查看");

        System.out.println("✅ TC-PERM-02 passed — 第三方用户查看他人订单返回403");
    }

    // ==================== TC-PERM-03 ====================

    /** TC-PERM-03：第三方无关用户结束他人订单 → 403 */
    @Test
    @DisplayName("TC-PERM-03: 第三方用户结束他人订单返回403")
    void tcPerm03_strangerFinishOrder_returns403() throws Exception {
        // 用户 A（盲人）+ 用户 B（志愿者）创建并接单
        String blindToken = testHelper.registerAndLoginWithRole("13800070011", "BLIND");
        String volToken = testHelper.registerAndLoginWithRole("13800070012", "VOLUNTEER");
        testHelper.updateVolunteerLocation(volToken, 39.9242, 116.4677, true);

        Long orderId = testHelper.createOrder(blindToken, 39.9042, 116.4674, "朝阳公园南门",
                TestHelper.defaultStartTime(), TestHelper.defaultEndTime());

        testHelper.waitForOrderStatus(blindToken, orderId,
                com.example.demo.entity.OrderStatus.PENDING_ACCEPT, 5);
        testHelper.acceptOrder(volToken, orderId);

        // 用户 C（陌生人）尝试结束订单
        String strangerToken = testHelper.registerAndLogin("13800070013");
        ResponseEntity<String> response = restTemplate.postForEntity(
                "/api/orders/" + orderId + "/finish",
                testHelper.jsonEntity(strangerToken, null), String.class);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN);
        JsonNode json = testHelper.extractJson(response.getBody());
        assertThat(json.get("success").asBoolean()).isFalse();
        assertThat(json.get("code").asInt()).isEqualTo(403);

        System.out.println("✅ TC-PERM-03 passed — 第三方用户结束他人订单返回403");
    }

    // ==================== TC-PERM-04 ====================

    /** TC-PERM-04：盲人用户尝试接单 → 403（志愿者认证校验失败） */
    @Test
    @DisplayName("TC-PERM-04: 盲人用户接单返回403")
    void tcPerm04_blindAcceptOrder_returns403() throws Exception {
        // 盲人 A 创建订单
        String blindToken = testHelper.registerAndLoginWithRole("13800070021", "BLIND");
        // 志愿者上线以便匹配
        String volToken = testHelper.registerAndLoginWithRole("13800070022", "VOLUNTEER");
        testHelper.updateVolunteerLocation(volToken, 39.9242, 116.4677, true);

        Long orderId = testHelper.createOrder(blindToken, 39.9042, 116.4674, "朝阳公园南门",
                TestHelper.defaultStartTime(), TestHelper.defaultEndTime());

        testHelper.waitForOrderStatus(blindToken, orderId,
                com.example.demo.entity.OrderStatus.PENDING_ACCEPT, 5);

        // 另一个盲人用户尝试接单
        String blindToken2 = testHelper.registerAndLoginWithRole("13800070023", "BLIND");
        ResponseEntity<String> response = testHelper.acceptOrderRaw(blindToken2, orderId);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN);
        JsonNode json = testHelper.extractJson(response.getBody());
        assertThat(json.get("success").asBoolean()).isFalse();
        assertThat(json.get("code").asInt()).isEqualTo(403);

        System.out.println("✅ TC-PERM-04 passed — 盲人用户接单返回403");
    }

    // ==================== TC-PERM-05 ====================

    /** TC-PERM-05：未认证志愿者接单 → 403 "请先完成志愿者认证" */
    @Test
    @DisplayName("TC-PERM-05: 未认证志愿者接单返回403")
    void tcPerm05_unverifiedVolunteerAccept_returns403() throws Exception {
        // 盲人创建订单
        String blindToken = testHelper.registerAndLoginWithRole("13800070031", "BLIND");
        // 已认证志愿者上线触发匹配
        String verifiedVolToken = testHelper.registerAndLoginWithRole("13800070032", "VOLUNTEER");
        testHelper.updateVolunteerLocation(verifiedVolToken, 39.9242, 116.4677, true);

        Long orderId = testHelper.createOrder(blindToken, 39.9042, 116.4674, "朝阳公园南门",
                TestHelper.defaultStartTime(), TestHelper.defaultEndTime());

        testHelper.waitForOrderStatus(blindToken, orderId,
                com.example.demo.entity.OrderStatus.PENDING_ACCEPT, 5);

        // 未认证志愿者尝试接单
        String unverifiedVolToken = testHelper.registerVolunteerWithoutVerification("13800070033");
        ResponseEntity<String> response = testHelper.acceptOrderRaw(unverifiedVolToken, orderId);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN);
        JsonNode json = testHelper.extractJson(response.getBody());
        assertThat(json.get("success").asBoolean()).isFalse();
        assertThat(json.get("code").asInt()).isEqualTo(403);
        assertThat(json.get("message").asText()).contains("请先完成志愿者认证");

        System.out.println("✅ TC-PERM-05 passed — 未认证志愿者接单返回403");
    }

    // ==================== TC-PERM-06 ====================

    /** TC-PERM-06：同一志愿者重复接单 → 第二次 409 */
    @Test
    @DisplayName("TC-PERM-06: 重复接单返回409")
    void tcPerm06_duplicateAccept_returns409() throws Exception {
        // 盲人创建订单
        String blindToken = testHelper.registerAndLoginWithRole("13800070041", "BLIND");
        String volToken = testHelper.registerAndLoginWithRole("13800070042", "VOLUNTEER");
        testHelper.updateVolunteerLocation(volToken, 39.9242, 116.4677, true);

        Long orderId = testHelper.createOrder(blindToken, 39.9042, 116.4674, "朝阳公园南门",
                TestHelper.defaultStartTime(), TestHelper.defaultEndTime());

        testHelper.waitForOrderStatus(blindToken, orderId,
                com.example.demo.entity.OrderStatus.PENDING_ACCEPT, 5);

        // 第一次接单成功
        testHelper.acceptOrder(volToken, orderId);

        // 第二次接单应失败
        ResponseEntity<String> response = testHelper.acceptOrderRaw(volToken, orderId);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CONFLICT);
        JsonNode json = testHelper.extractJson(response.getBody());
        assertThat(json.get("success").asBoolean()).isFalse();
        assertThat(json.get("code").asInt()).isEqualTo(409);

        System.out.println("✅ TC-PERM-06 passed — 重复接单返回409");
    }

    // ==================== TC-PERM-07 ====================

    /** TC-PERM-07：盲人有进行中的订单时重复下单 → 409 */
    @Test
    @DisplayName("TC-PERM-07: 有进行中订单时重复下单返回409")
    void tcPerm07_duplicateOrderWhileActive_returns409() throws Exception {
        // 盲人创建第一个订单
        String blindToken = testHelper.registerAndLoginWithRole("13800070051", "BLIND");
        String volToken = testHelper.registerAndLoginWithRole("13800070052", "VOLUNTEER");
        testHelper.updateVolunteerLocation(volToken, 39.9242, 116.4677, true);

        Long firstOrderId = testHelper.createOrder(blindToken, 39.9042, 116.4674, "朝阳公园南门",
                TestHelper.defaultStartTime(), TestHelper.defaultEndTime());

        // 等待第一个订单匹配（进入 PENDING_MATCH 或更后的状态）
        testHelper.waitForOrderStatus(blindToken, firstOrderId,
                com.example.demo.entity.OrderStatus.PENDING_ACCEPT, 5);

        // 盲人尝试创建第二个订单 → 应被拒绝
        ResponseEntity<String> response = testHelper.createOrderRaw(blindToken, """
                {"startLatitude":39.91,"startLongitude":116.47,"startAddress":"东直门",
                 "plannedStartTime":"2099-07-01T18:00:00","plannedEndTime":"2099-07-01T19:00:00"}
                """);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CONFLICT);
        JsonNode json = testHelper.extractJson(response.getBody());
        assertThat(json.get("success").asBoolean()).isFalse();
        assertThat(json.get("code").asInt()).isEqualTo(409);
        assertThat(json.get("message").asText()).contains("进行中的订单");

        System.out.println("✅ TC-PERM-07 passed — 有进行中订单时重复下单返回409");
    }
}
