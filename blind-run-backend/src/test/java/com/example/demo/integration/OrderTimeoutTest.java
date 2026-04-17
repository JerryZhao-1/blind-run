package com.example.demo.integration;

import com.example.demo.entity.OrderStatus;
import com.example.demo.entity.RunOrder;
import com.example.demo.repository.RunOrderRepository;
import com.example.demo.scheduler.OrderTimeoutScheduler;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.time.LocalDateTime;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * 超时自动完成集成测试（TC-TIMEOUT-01 ~ 02）
 * 标记为 slow，默认 CI 跳过
 */
@Tag("slow")
class OrderTimeoutTest extends BaseIntegrationTest {

    @Autowired
    private OrderTimeoutScheduler orderTimeoutScheduler;

    @Autowired
    private RunOrderRepository runOrderRepository;

    /** TC-TIMEOUT-01：超时订单被自动完成 */
    @Test
    @DisplayName("TC-TIMEOUT-01: 超时自动完成订单")
    void tc01_autoCompleteTimedOut() throws Exception {
        // 1. 创建并推进订单到 IN_PROGRESS
        TestHelper.FlowResult flow = testHelper.setupOrderInProgress("13800120001", "13800120002");

        assertThat(testHelper.getOrderStatus(flow.blindToken(), flow.orderId()))
                .isEqualTo(OrderStatus.IN_PROGRESS);

        // 2. 将 plannedEndTime 设为过去时间（模拟超时）
        RunOrder order = runOrderRepository.findById(flow.orderId()).orElseThrow();
        order.setPlannedEndTime(LocalDateTime.now().minusMinutes(2));
        runOrderRepository.save(order);

        // 3. 直接调用定时任务方法
        orderTimeoutScheduler.autoCompleteTimedOutOrders();

        // 4. 验证订单已被自动完成
        assertThat(testHelper.getOrderStatus(flow.blindToken(), flow.orderId()))
                .isEqualTo(OrderStatus.COMPLETED);

        RunOrder updated = runOrderRepository.findById(flow.orderId()).orElseThrow();
        assertThat(updated.getFinishedAt()).isNotNull();

        System.out.println("✅ TC-TIMEOUT-01 passed — 超时自动完成订单");
    }

    /** TC-TIMEOUT-02：未超时的订单不被自动完成 */
    @Test
    @DisplayName("TC-TIMEOUT-02: 未超时订单不受影响")
    void tc02_notTimedOut() throws Exception {
        TestHelper.FlowResult flow = testHelper.setupOrderInProgress("13800120003", "13800120004");

        // plannedEndTime 在未来（默认 +2 小时），不修改
        orderTimeoutScheduler.autoCompleteTimedOutOrders();

        // 订单仍为 IN_PROGRESS
        assertThat(testHelper.getOrderStatus(flow.blindToken(), flow.orderId()))
                .isEqualTo(OrderStatus.IN_PROGRESS);

        System.out.println("✅ TC-TIMEOUT-02 passed — 未超时订单不受影响");
    }
}
