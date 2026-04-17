package com.example.demo.integration;

import com.example.demo.entity.OrderStatus;
import com.fasterxml.jackson.databind.JsonNode;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * 订单流程集成测试（TC-ORDER-01 ~ 06）
 *
 * 手机号前缀: 1380005xxx
 */
class OrderFlowTest extends BaseIntegrationTest {

    // ==================== 完整流程 ====================

    /** TC-ORDER-01: 完整成功流程 — 志愿者上报位置 → 盲人创建订单 → 等待PENDING_ACCEPT → 接单 → 完成 */
    @Test
    @DisplayName("TC-ORDER-01: 完整成功流程")
    void tc01_completeOrderFlow() throws Exception {
        // 注册盲人和志愿者
        String blindToken = testHelper.registerAndLoginWithRole("13800050001", "BLIND");
        String volToken = testHelper.registerAndLoginWithRole("13800050002", "VOLUNTEER");

        // 志愿者上报位置并上线
        testHelper.updateVolunteerLocation(volToken, 39.9242, 116.4677, true);

        // 盲人创建订单
        Long orderId = testHelper.createOrder(blindToken, 39.9042, 116.4674, "朝阳公园南门",
                TestHelper.defaultStartTime(), TestHelper.defaultEndTime());

        // 验证初始状态为 PENDING_MATCH
        OrderStatus status = testHelper.getOrderStatus(blindToken, orderId);
        assertThat(status).isEqualTo(OrderStatus.PENDING_MATCH);

        // 等待系统匹配 → PENDING_ACCEPT
        testHelper.waitForOrderStatus(blindToken, orderId, OrderStatus.PENDING_ACCEPT, 5);
        assertThat(testHelper.getOrderStatus(blindToken, orderId)).isEqualTo(OrderStatus.PENDING_ACCEPT);

        // 志愿者接单 → IN_PROGRESS
        testHelper.acceptOrder(volToken, orderId);
        assertThat(testHelper.getOrderStatus(blindToken, orderId)).isEqualTo(OrderStatus.IN_PROGRESS);

        // 志愿者完成服务 → COMPLETED
        testHelper.finishOrder(volToken, orderId);
        assertThat(testHelper.getOrderStatus(blindToken, orderId)).isEqualTo(OrderStatus.COMPLETED);

        System.out.println("✅ TC-ORDER-01 passed — 完整成功流程");
    }

    // ==================== 订单详情查询 ====================

    /** TC-ORDER-02: 订单详情查询 — 验证完成后各字段正确 */
    @Test
    @DisplayName("TC-ORDER-02: 订单详情查询")
    void tc02_orderDetailQuery() throws Exception {
        // 使用完整流程创建并完成订单
        TestHelper.FlowResult result = testHelper.completeOrderFlow("13800050011", "13800050012");

        // 查询订单详情
        ResponseEntity<String> response = testHelper.getOrder(result.blindToken(), result.orderId());
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);

        JsonNode detail = testHelper.extractJson(response.getBody());

        // 验证状态为 COMPLETED
        assertThat(detail.get("status").asText()).isEqualTo("COMPLETED");

        // 验证志愿者电话已脱敏（前3后4，中间****）
        String volunteerPhone = detail.get("volunteerPhone").asText();
        assertThat(volunteerPhone).matches("\\d{3}\\*{4}\\d{4}");

        // 验证 acceptedAt 非空（接单时间存在）
        assertThat(detail.get("acceptedAt").isNull()).isFalse();

        // 验证其他基础字段
        assertThat(detail.get("orderId").asLong()).isEqualTo(result.orderId());
        assertThat(detail.get("startAddress").asText()).isEqualTo("朝阳公园南门");

        System.out.println("✅ TC-ORDER-02 passed — 订单详情查询");
    }

    // ==================== 我的订单（盲人视角） ====================

    /** TC-ORDER-03: 盲人查看我的订单 */
    @Test
    @DisplayName("TC-ORDER-03: 盲人查看我的订单")
    void tc03_blindMyOrders() throws Exception {
        // 创建并完成 1 个订单
        TestHelper.FlowResult result = testHelper.completeOrderFlow("13800050021", "13800050022");

        // 盲人查看我的订单
        ResponseEntity<String> response = testHelper.getMyOrders(result.blindToken(), "BLIND", null, 0, 10);
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);

        JsonNode page = testHelper.extractJson(response.getBody());
        assertThat(page.get("totalElements").asInt()).isGreaterThanOrEqualTo(1);

        // 验证内容不为空
        JsonNode content = page.get("content");
        assertThat(content.isArray()).isTrue();
        assertThat(content.size()).isGreaterThanOrEqualTo(1);

        System.out.println("✅ TC-ORDER-03 passed — 盲人查看我的订单");
    }

    /** TC-ORDER-04: 我的订单按状态过滤 */
    @Test
    @DisplayName("TC-ORDER-04: 我的订单按状态过滤")
    void tc04_myOrdersWithStatusFilter() throws Exception {
        // 创建并完成 1 个订单
        TestHelper.FlowResult result = testHelper.completeOrderFlow("13800050031", "13800050032");

        // 查询 COMPLETED 状态的订单
        ResponseEntity<String> response = testHelper.getMyOrders(result.blindToken(), "BLIND", "COMPLETED", 0, 10);
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);

        JsonNode page = testHelper.extractJson(response.getBody());
        assertThat(page.get("totalElements").asInt()).isGreaterThanOrEqualTo(1);

        // 验证所有返回的订单都是 COMPLETED 状态
        JsonNode content = page.get("content");
        for (JsonNode order : content) {
            assertThat(order.get("status").asText()).isEqualTo("COMPLETED");
        }

        System.out.println("✅ TC-ORDER-04 passed — 我的订单按状态过滤");
    }

    // ==================== 我的订单（志愿者视角） ====================

    /** TC-ORDER-05: 志愿者查看已接订单 */
    @Test
    @DisplayName("TC-ORDER-05: 志愿者查看已接订单")
    void tc05_volunteerMyOrders() throws Exception {
        // 创建并完成订单（志愿者接单）
        TestHelper.FlowResult result = testHelper.completeOrderFlow("13800050041", "13800050042");

        // 志愿者查看我的订单
        ResponseEntity<String> response = testHelper.getMyOrders(result.volToken(), "VOLUNTEER", null, 0, 10);
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);

        JsonNode page = testHelper.extractJson(response.getBody());
        assertThat(page.get("totalElements").asInt()).isGreaterThanOrEqualTo(1);

        // 验证内容不为空
        JsonNode content = page.get("content");
        assertThat(content.isArray()).isTrue();
        assertThat(content.size()).isGreaterThanOrEqualTo(1);

        System.out.println("✅ TC-ORDER-05 passed — 志愿者查看已接订单");
    }

    // ==================== 可接订单列表 ====================

    /** TC-ORDER-06: 志愿者查看可接订单列表 */
    @Test
    @DisplayName("TC-ORDER-06: 志愿者查看可接订单列表")
    void tc06_availableOrders() throws Exception {
        // 注册盲人和两个志愿者
        String blindToken = testHelper.registerAndLoginWithRole("13800050051", "BLIND");
        String volToken1 = testHelper.registerAndLoginWithRole("13800050052", "VOLUNTEER");
        // 第二个志愿者用于查询可接订单（不会自动匹配到这个订单）
        String volToken2 = testHelper.registerAndLoginWithRole("13800050053", "VOLUNTEER");

        // 第一个志愿者上线，用于匹配
        testHelper.updateVolunteerLocation(volToken1, 39.9242, 116.4677, true);

        // 盲人创建订单
        Long orderId = testHelper.createOrder(blindToken, 39.9042, 116.4674, "朝阳公园南门",
                TestHelper.defaultStartTime(), TestHelper.defaultEndTime());

        // 等待匹配完成 → PENDING_ACCEPT
        testHelper.waitForOrderStatus(blindToken, orderId, OrderStatus.PENDING_ACCEPT, 5);

        // 第二个志愿者上线并查询可接订单
        testHelper.updateVolunteerLocation(volToken2, 39.9242, 116.4677, true);
        ResponseEntity<String> response = testHelper.getAvailableOrders(volToken2);
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);

        // 验证返回的列表中包含该订单
        JsonNode orders = testHelper.extractJson(response.getBody());
        assertThat(orders.isArray()).isTrue();

        // 可接订单列表应包含至少一个 PENDING_ACCEPT 的订单
        boolean found = false;
        for (JsonNode order : orders) {
            if (order.get("orderId").asLong() == orderId) {
                found = true;
                break;
            }
        }
        assertThat(found).as("可接订单列表应包含订单 %d", orderId).isTrue();

        System.out.println("✅ TC-ORDER-06 passed — 志愿者查看可接订单列表");
    }
}
