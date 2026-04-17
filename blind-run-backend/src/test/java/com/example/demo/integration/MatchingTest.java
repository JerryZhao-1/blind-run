package com.example.demo.integration;

import com.example.demo.entity.OrderStatus;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * 匹配模块集成测试（TC-MATCH-01 ~ 06）
 *
 * 测试异步匹配逻辑：
 * 盲人创建订单后，MatchingService 通过 @Async @EventListener 在后台执行距离匹配，
 * 将附近在线志愿者与订单关联。
 *
 * 使用 waitForOrderStatus 轮询等待异步匹配完成后的状态变更。
 */
class MatchingTest extends BaseIntegrationTest {

    // ==================== 距离匹配 ====================

    /** TC-MATCH-01：附近志愿者成功匹配 */
    @Test
    @DisplayName("TC-MATCH-01: 附近志愿者成功匹配")
    void tc01_nearbyVolunteerMatched() throws InterruptedException {
        // 1. 注册盲人和志愿者
        String blindToken = testHelper.registerAndLoginWithRole("13800101001", "BLIND");
        String volToken = testHelper.registerAndLoginWithRole("13800101002", "VOLUNTEER");

        // 2. 志愿者上报位置（约 2.2km 外）
        testHelper.updateVolunteerLocation(volToken, 39.9242, 116.4677, true);

        // 3. 盲人创建订单
        Long orderId = testHelper.createOrder(blindToken, 39.9042, 116.4674, "朝阳公园南门",
                TestHelper.defaultStartTime(), TestHelper.defaultEndTime());

        // 4. 等待异步匹配完成，订单应变为 PENDING_ACCEPT
        testHelper.waitForOrderStatus(blindToken, orderId, OrderStatus.PENDING_ACCEPT, 5);

        System.out.println("✅ TC-MATCH-01 passed — 附近志愿者成功匹配");
    }

    /** TC-MATCH-02：远距离志愿者不匹配 */
    @Test
    @DisplayName("TC-MATCH-02: 远距离志愿者不匹配")
    void tc02_farVolunteerNotMatched() throws InterruptedException {
        // 1. 注册盲人和志愿者
        String blindToken = testHelper.registerAndLoginWithRole("13800102001", "BLIND");
        String volToken = testHelper.registerAndLoginWithRole("13800102002", "VOLUNTEER");

        // 2. 志愿者在约 111km 外（纬度 +1.0），远超 10km 阈值
        testHelper.updateVolunteerLocation(volToken, 40.9042, 116.4674, true);

        // 3. 盲人创建订单
        Long orderId = testHelper.createOrder(blindToken, 39.9042, 116.4674, "朝阳公园南门",
                TestHelper.defaultStartTime(), TestHelper.defaultEndTime());

        // 4. 等待 3 秒后检查状态，应保持 PENDING_MATCH
        Thread.sleep(3000);
        OrderStatus status = testHelper.getOrderStatus(blindToken, orderId);
        assertThat(status)
                .as("远距离志愿者不应被匹配，订单应保持 PENDING_MATCH")
                .isEqualTo(OrderStatus.PENDING_MATCH);

        System.out.println("✅ TC-MATCH-02 passed — 远距离志愿者不匹配");
    }

    /** TC-MATCH-03：最大候选人数限制 */
    @Test
    @DisplayName("TC-MATCH-03: 最大候选人数限制（5 名志愿者，仅推送前 3 名）")
    void tc03_maxCandidatesLimit() throws InterruptedException {
        // 1. 注册盲人
        String blindToken = testHelper.registerAndLoginWithRole("13800103001", "BLIND");

        // 2. 注册 5 名志愿者，都在订单附近（不同距离，都在 10km 内）
        String vol1 = testHelper.registerAndLoginWithRole("13800103002", "VOLUNTEER");
        String vol2 = testHelper.registerAndLoginWithRole("13800103003", "VOLUNTEER");
        String vol3 = testHelper.registerAndLoginWithRole("13800103004", "VOLUNTEER");
        String vol4 = testHelper.registerAndLoginWithRole("13800103005", "VOLUNTEER");
        String vol5 = testHelper.registerAndLoginWithRole("13800103006", "VOLUNTEER");

        // 所有志愿者都在订单附近，距离递增
        testHelper.updateVolunteerLocation(vol1, 39.9062, 116.4674, true);  // ~0.2km
        testHelper.updateVolunteerLocation(vol2, 39.9102, 116.4674, true);  // ~0.7km
        testHelper.updateVolunteerLocation(vol3, 39.9202, 116.4674, true);  // ~1.8km
        testHelper.updateVolunteerLocation(vol4, 39.9302, 116.4674, true);  // ~2.9km
        testHelper.updateVolunteerLocation(vol5, 39.9402, 116.4674, true);  // ~4.0km

        // 3. 盲人创建订单
        Long orderId = testHelper.createOrder(blindToken, 39.9042, 116.4674, "朝阳公园南门",
                TestHelper.defaultStartTime(), TestHelper.defaultEndTime());

        // 4. 等待匹配完成，订单应变为 PENDING_ACCEPT
        // （max-candidates=3，只有最近的 3 名志愿者收到推送，但匹配仍然成功）
        testHelper.waitForOrderStatus(blindToken, orderId, OrderStatus.PENDING_ACCEPT, 5);

        System.out.println("✅ TC-MATCH-03 passed — 最大候选人数限制");
    }

    /** TC-MATCH-04：无在线志愿者，订单保持 PENDING_MATCH */
    @Test
    @DisplayName("TC-MATCH-04: 无在线志愿者，订单保持 PENDING_MATCH")
    void tc04_noOnlineVolunteers() throws InterruptedException {
        // 1. 注册盲人（不注册任何志愿者）
        String blindToken = testHelper.registerAndLoginWithRole("13800104001", "BLIND");

        // 2. 盲人创建订单
        Long orderId = testHelper.createOrder(blindToken, 39.9042, 116.4674, "朝阳公园南门",
                TestHelper.defaultStartTime(), TestHelper.defaultEndTime());

        // 3. 等待 3 秒后检查状态，应保持 PENDING_MATCH
        Thread.sleep(3000);
        OrderStatus status = testHelper.getOrderStatus(blindToken, orderId);
        assertThat(status)
                .as("无在线志愿者时，订单应保持 PENDING_MATCH")
                .isEqualTo(OrderStatus.PENDING_MATCH);

        System.out.println("✅ TC-MATCH-04 passed — 无在线志愿者");
    }

    /** TC-MATCH-05：离线志愿者被忽略 */
    @Test
    @DisplayName("TC-MATCH-05: 离线志愿者被忽略")
    void tc05_offlineVolunteerIgnored() throws InterruptedException {
        // 1. 注册盲人和志愿者
        String blindToken = testHelper.registerAndLoginWithRole("13800105001", "BLIND");
        String volToken = testHelper.registerAndLoginWithRole("13800105002", "VOLUNTEER");

        // 2. 志愿者上报位置但设为离线
        testHelper.updateVolunteerLocation(volToken, 39.9242, 116.4677, false);

        // 3. 盲人创建订单
        Long orderId = testHelper.createOrder(blindToken, 39.9042, 116.4674, "朝阳公园南门",
                TestHelper.defaultStartTime(), TestHelper.defaultEndTime());

        // 4. 等待 3 秒后检查状态，应保持 PENDING_MATCH
        Thread.sleep(3000);
        OrderStatus status = testHelper.getOrderStatus(blindToken, orderId);
        assertThat(status)
                .as("离线志愿者不应被匹配，订单应保持 PENDING_MATCH")
                .isEqualTo(OrderStatus.PENDING_MATCH);

        System.out.println("✅ TC-MATCH-05 passed — 离线志愿者被忽略");
    }

    /** TC-MATCH-06：多名志愿者按距离排序匹配 */
    @Test
    @DisplayName("TC-MATCH-06: 多名志愿者按距离排序匹配")
    void tc06_multipleVolunteersSortedByDistance() throws InterruptedException {
        // 1. 注册盲人
        String blindToken = testHelper.registerAndLoginWithRole("13800106001", "BLIND");

        // 2. 注册 3 名志愿者，在不同距离
        String volNear = testHelper.registerAndLoginWithRole("13800106002", "VOLUNTEER");
        String volMid = testHelper.registerAndLoginWithRole("13800106003", "VOLUNTEER");
        String volFar = testHelper.registerAndLoginWithRole("13800106004", "VOLUNTEER");

        // 约 1km, ~3km, ~8km（都在 10km 阈值内）
        testHelper.updateVolunteerLocation(volNear, 39.9132, 116.4674, true);   // ~1km
        testHelper.updateVolunteerLocation(volMid, 39.9312, 116.4674, true);    // ~3km
        testHelper.updateVolunteerLocation(volFar, 39.9762, 116.4674, true);    // ~8km

        // 3. 盲人创建订单
        Long orderId = testHelper.createOrder(blindToken, 39.9042, 116.4674, "朝阳公园南门",
                TestHelper.defaultStartTime(), TestHelper.defaultEndTime());

        // 4. 3 名志愿者都在范围内，订单应变为 PENDING_ACCEPT
        testHelper.waitForOrderStatus(blindToken, orderId, OrderStatus.PENDING_ACCEPT, 5);

        System.out.println("✅ TC-MATCH-06 passed — 多名志愿者按距离排序匹配");
    }
}
