package com.example.demo.util;

/**
 * 地理位置工具类 —— 提供距离计算等地理相关方法
 *
 * 【Haversine 公式是什么？】
 * 用于计算地球表面两点之间的最短距离（大圆距离）。
 * 地球不是平的，是球体，所以不能用简单的勾股定理。
 * Haversine 公式考虑了地球的曲率，计算结果比较精确。
 *
 * 【参数说明】
 * 纬度 latitude：  南北方向，-90（南极）到 90（北极）
 * 经度 longitude： 东西方向，-180 到 180
 * 北京大约在 纬度39.9, 经度116.4
 *
 * 【返回值】
 * 两点之间的距离，单位：公里（km）
 */
public class GeoUtils {

    /** 地球平均半径，单位：公里 */
    private static final double EARTH_RADIUS_KM = 6371.0;

    /**
     * 使用 Haversine 公式计算两点之间的球面距离
     *
     * @param lat1 第一个点的纬度
     * @param lng1 第一个点的经度
     * @param lat2 第二个点的纬度
     * @param lng2 第二个点的经度
     * @return 两点之间的距离（公里）
     */
    public static double distanceKm(double lat1, double lng1, double lat2, double lng2) {
        // 将角度转为弧度
        double lat1Rad = Math.toRadians(lat1);
        double lat2Rad = Math.toRadians(lat2);
        double deltaLat = Math.toRadians(lat2 - lat1);
        double deltaLng = Math.toRadians(lng2 - lng1);

        // Haversine 公式
        double a = Math.sin(deltaLat / 2) * Math.sin(deltaLat / 2)
                + Math.cos(lat1Rad) * Math.cos(lat2Rad)
                * Math.sin(deltaLng / 2) * Math.sin(deltaLng / 2);

        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

        return EARTH_RADIUS_KM * c;
    }
}
