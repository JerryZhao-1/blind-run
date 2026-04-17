package com.example.demo.util;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

/**
 * GeoUtils 单元测试 —— 验证 Haversine 距离计算的正确性
 */
class GeoUtilsTest {

    /**
     * 测试北京到上海的距离
     * 北京：(39.9042, 116.4074)
     * 上海：(31.2304, 121.4737)
     * 实际距离约 1068 公里，允许误差 ±10 公里
     */
    @Test
    void testBeijingToShanghai() {
        double distance = GeoUtils.distanceKm(39.9042, 116.4074, 31.2304, 121.4737);
        assertTrue(distance > 1058 && distance < 1078,
                "北京到上海距离应约为1068km，实际: " + distance + "km");
    }

    /**
     * 测试相同坐标的距离为 0
     */
    @Test
    void testSamePoint() {
        double distance = GeoUtils.distanceKm(39.9042, 116.4074, 39.9042, 116.4074);
        assertEquals(0.0, distance, 0.001, "相同坐标距离应为0");
    }

    /**
     * 测试短距离（约 1 公里）
     * 朝阳公园南门到朝阳公园北门约 1.5 公里
     */
    @Test
    void testShortDistance() {
        // 朝阳公园南门
        double lat1 = 39.9340, lng1 = 116.4740;
        // 朝阳公园北门（约1.5km以北）
        double lat2 = 39.9475, lng2 = 116.4740;

        double distance = GeoUtils.distanceKm(lat1, lng1, lat2, lng2);
        assertTrue(distance > 1.0 && distance < 2.0,
                "短距离应约为1.5km，实际: " + distance + "km");
    }
}
