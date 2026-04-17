package com.example.demo.integration;

import com.fasterxml.jackson.databind.JsonNode;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;


import static org.assertj.core.api.Assertions.assertThat;

/**
 * 订单参数校验测试（TC-VALID-01 ~ 07）
 *
 * 验证创建订单时的各类输入校验：
 * 时间逻辑、必填字段、业务规则（重复订单等）
 */
class OrderValidationTest extends BaseIntegrationTest {

    // ==================== TC-VALID-01 ====================

    /** TC-VALID-01：plannedEnd 早于 plannedStart → 400 */
    @Test
    @DisplayName("TC-VALID-01: 结束时间早于开始时间返回400")
    void tcValid01_endBeforeStart_returns400() {
        String blindToken = testHelper.registerAndLoginWithRole("13800080001", "BLIND");

        ResponseEntity<String> response = testHelper.createOrderRaw(blindToken, """
                {"startLatitude":39.9,"startLongitude":116.4,"startAddress":"test",
                 "plannedStartTime":"2099-06-01T18:00:00","plannedEndTime":"2099-06-01T17:00:00"}
                """);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        JsonNode json = testHelper.extractJson(response.getBody());
        assertThat(json.get("success").asBoolean()).isFalse();
        assertThat(json.get("code").asInt()).isEqualTo(400);
        assertThat(json.get("message").asText()).contains("结束时间必须晚于开始时间");

        System.out.println("✅ TC-VALID-01 passed — 结束时间早于开始时间返回400");
    }

    // ==================== TC-VALID-02 ====================

    /** TC-VALID-02：plannedStart 在过去 → 400 */
    @Test
    @DisplayName("TC-VALID-02: 开始时间在过去返回400")
    void tcValid02_startTimeInPast_returns400() {
        String blindToken = testHelper.registerAndLoginWithRole("13800080002", "BLIND");

        ResponseEntity<String> response = testHelper.createOrderRaw(blindToken, """
                {"startLatitude":39.9,"startLongitude":116.4,"startAddress":"test",
                 "plannedStartTime":"2020-01-01T10:00:00","plannedEndTime":"2020-01-01T11:00:00"}
                """);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        JsonNode json = testHelper.extractJson(response.getBody());
        assertThat(json.get("success").asBoolean()).isFalse();
        assertThat(json.get("code").asInt()).isEqualTo(400);
        assertThat(json.get("message").asText()).contains("开始时间不能早于当前时间");

        System.out.println("✅ TC-VALID-02 passed — 开始时间在过去返回400");
    }

    // ==================== TC-VALID-03 ====================

    /** TC-VALID-03：缺少 startLatitude → 400 */
    @Test
    @DisplayName("TC-VALID-03: 缺少纬度返回400")
    void tcValid03_missingLatitude_returns400() {
        String blindToken = testHelper.registerAndLoginWithRole("13800080003", "BLIND");

        ResponseEntity<String> response = testHelper.createOrderRaw(blindToken, """
                {"startLongitude":116.4,"startAddress":"test",
                 "plannedStartTime":"2099-06-01T18:00:00","plannedEndTime":"2099-06-01T19:00:00"}
                """);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        JsonNode json = testHelper.extractJson(response.getBody());
        assertThat(json.get("success").asBoolean()).isFalse();
        assertThat(json.get("code").asInt()).isEqualTo(400);
        assertThat(json.get("message").asText()).contains("startLatitude");

        System.out.println("✅ TC-VALID-03 passed — 缺少纬度返回400");
    }

    // ==================== TC-VALID-04 ====================

    /** TC-VALID-04：缺少 startAddress → 400 */
    @Test
    @DisplayName("TC-VALID-04: 缺少地址返回400")
    void tcValid04_missingAddress_returns400() {
        String blindToken = testHelper.registerAndLoginWithRole("13800080004", "BLIND");

        ResponseEntity<String> response = testHelper.createOrderRaw(blindToken, """
                {"startLatitude":39.9,"startLongitude":116.4,
                 "plannedStartTime":"2099-06-01T18:00:00","plannedEndTime":"2099-06-01T19:00:00"}
                """);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        JsonNode json = testHelper.extractJson(response.getBody());
        assertThat(json.get("success").asBoolean()).isFalse();
        assertThat(json.get("code").asInt()).isEqualTo(400);
        assertThat(json.get("message").asText()).contains("startAddress");

        System.out.println("✅ TC-VALID-04 passed — 缺少地址返回400");
    }

    // ==================== TC-VALID-05 ====================

    /** TC-VALID-05：缺少 plannedStartTime 和 plannedEndTime → 400 */
    @Test
    @DisplayName("TC-VALID-05: 缺少计划时间返回400")
    void tcValid05_missingPlannedTimes_returns400() {
        String blindToken = testHelper.registerAndLoginWithRole("13800080005", "BLIND");

        ResponseEntity<String> response = testHelper.createOrderRaw(blindToken, """
                {"startLatitude":39.9,"startLongitude":116.4,"startAddress":"test"}
                """);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        JsonNode json = testHelper.extractJson(response.getBody());
        assertThat(json.get("success").asBoolean()).isFalse();
        assertThat(json.get("code").asInt()).isEqualTo(400);
        // 校验失败消息中应包含 plannedStartTime 或 plannedEndTime
        String message = json.get("message").asText();
        assertThat(message).containsAnyOf("plannedStartTime", "plannedEndTime");

        System.out.println("✅ TC-VALID-05 passed — 缺少计划时间返回400");
    }

    // ==================== TC-VALID-06 ====================

    /** TC-VALID-06：已完成的订单不影响再次下单 → 201 */
    @Test
    @DisplayName("TC-VALID-06: 完成订单后可再次下单返回201")
    void tcValid06_completedOrderAllowsNewOrder_returns201() throws Exception {
        // 完成一个完整订单流程
        TestHelper.FlowResult flow = testHelper.completeOrderFlow("13800080061", "13800080062");

        // 验证第一个订单已完成
        var status = testHelper.getOrderStatus(flow.blindToken(), flow.orderId());
        assertThat(status).isEqualTo(com.example.demo.entity.OrderStatus.COMPLETED);

        // 盲人再次创建订单 → 应成功
        Long secondOrderId = testHelper.createOrder(flow.blindToken(), 39.91, 116.47, "东直门",
                TestHelper.defaultStartTime(), TestHelper.defaultEndTime());

        assertThat(secondOrderId).as("第二个订单ID应大于0").isGreaterThan(0);

        System.out.println("✅ TC-VALID-06 passed — 完成订单后可再次下单返回201");
    }

    // ==================== TC-VALID-07 ====================

    /** TC-VALID-07：PENDING_ACCEPT 状态也触发重复订单检查 → 409 */
    @Test
    @DisplayName("TC-VALID-07: PENDING_ACCEPT状态触发重复下单检查返回409")
    void tcValid07_pendingAcceptTriggersDuplicateCheck_returns409() throws Exception {
        String blindToken = testHelper.registerAndLoginWithRole("13800080071", "BLIND");
        String volToken = testHelper.registerAndLoginWithRole("13800080072", "VOLUNTEER");
        testHelper.updateVolunteerLocation(volToken, 39.9242, 116.4677, true);

        // 创建第一个订单，等待进入 PENDING_ACCEPT
        Long orderId = testHelper.createOrder(blindToken, 39.9042, 116.4674, "朝阳公园南门",
                TestHelper.defaultStartTime(), TestHelper.defaultEndTime());

        testHelper.waitForOrderStatus(blindToken, orderId,
                com.example.demo.entity.OrderStatus.PENDING_ACCEPT, 5);

        // 此时订单处于 PENDING_ACCEPT，盲人尝试创建第二个订单 → 应被拒绝
        ResponseEntity<String> response = testHelper.createOrderRaw(blindToken, """
                {"startLatitude":39.91,"startLongitude":116.47,"startAddress":"东直门",
                 "plannedStartTime":"2099-07-01T18:00:00","plannedEndTime":"2099-07-01T19:00:00"}
                """);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CONFLICT);
        JsonNode json = testHelper.extractJson(response.getBody());
        assertThat(json.get("success").asBoolean()).isFalse();
        assertThat(json.get("code").asInt()).isEqualTo(409);
        assertThat(json.get("message").asText()).contains("进行中的订单");

        System.out.println("✅ TC-VALID-07 passed — PENDING_ACCEPT状态触发重复下单检查返回409");
    }
}
