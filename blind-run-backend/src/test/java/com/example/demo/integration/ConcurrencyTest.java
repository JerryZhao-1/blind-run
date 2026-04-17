package com.example.demo.integration;

import com.example.demo.entity.OrderStatus;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * 并发安全测试（TC-CONCUR-01）
 * 验证乐观锁防止多个志愿者同时接同一订单
 */
@Tag("slow")
class ConcurrencyTest extends BaseIntegrationTest {

    /** TC-CONCUR-01：两个志愿者并发接同一订单 */
    @Test
    @DisplayName("TC-CONCUR-01: 并发接单竞争")
    void tc01_concurrentAccept() throws Exception {
        // 1. 注册盲人 + 两个志愿者
        String blindToken = testHelper.registerAndLoginWithRole("13800130001", "BLIND");
        String volAToken = testHelper.registerAndLoginWithRole("13800130002", "VOLUNTEER");
        String volBToken = testHelper.registerAndLoginWithRole("13800130003", "VOLUNTEER");

        // 2. 两个志愿者都上报位置
        testHelper.updateVolunteerLocation(volAToken, 39.9242, 116.4677, true);
        testHelper.updateVolunteerLocation(volBToken, 39.9300, 116.4680, true);

        // 3. 盲人下单 → 等待 PENDING_ACCEPT
        Long orderId = testHelper.createOrder(blindToken, 39.9042, 116.4674, "朝阳公园南门",
                TestHelper.defaultStartTime(), TestHelper.defaultEndTime());

        testHelper.waitForOrderStatus(blindToken, orderId, OrderStatus.PENDING_ACCEPT, 5);

        // 4. 用 CountDownLatch 保证两个线程同时发起 accept
        CountDownLatch startLatch = new CountDownLatch(1);
        CountDownLatch doneLatch = new CountDownLatch(2);

        AtomicInteger successCount = new AtomicInteger(0);
        AtomicInteger conflictCount = new AtomicInteger(0);

        Runnable acceptA = () -> {
            try {
                startLatch.await();
                ResponseEntity<String> resp = testHelper.acceptOrderRaw(volAToken, orderId);
                if (resp.getStatusCode() == HttpStatus.OK) successCount.incrementAndGet();
                else if (resp.getStatusCode() == HttpStatus.CONFLICT) conflictCount.incrementAndGet();
            } catch (Exception e) {
                // 连接异常等
            } finally {
                doneLatch.countDown();
            }
        };

        Runnable acceptB = () -> {
            try {
                startLatch.await();
                ResponseEntity<String> resp = testHelper.acceptOrderRaw(volBToken, orderId);
                if (resp.getStatusCode() == HttpStatus.OK) successCount.incrementAndGet();
                else if (resp.getStatusCode() == HttpStatus.CONFLICT) conflictCount.incrementAndGet();
            } catch (Exception e) {
                // 连接异常等
            } finally {
                doneLatch.countDown();
            }
        };

        new Thread(acceptA, "vol-A").start();
        new Thread(acceptB, "vol-B").start();

        // 同时放开两个线程
        startLatch.countDown();
        doneLatch.await(10, TimeUnit.SECONDS);

        // 5. 断言：恰好一个成功，一个 409
        assertThat(successCount.get()).as("应该恰好一个志愿者接单成功").isEqualTo(1);
        assertThat(conflictCount.get()).as("应该恰好一个志愿者被拒绝").isEqualTo(1);

        // 6. 订单最终状态 IN_PROGRESS
        assertThat(testHelper.getOrderStatus(blindToken, orderId))
                .isEqualTo(OrderStatus.IN_PROGRESS);

        System.out.println("✅ TC-CONCUR-01 passed — 并发接单竞争");
    }
}
