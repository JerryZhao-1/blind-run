package com.example.demo.service;

import com.example.demo.entity.User;
import com.example.demo.entity.VolunteerLocation;
import com.example.demo.repository.UserRepository;
import com.example.demo.repository.VolunteerLocationRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.*;
import java.util.concurrent.TimeUnit;

/**
 * 志愿者位置服务 —— 处理位置上报和查询
 *
 * 【核心职责】
 * 1. 保存志愿者上报的 GPS 位置（同时写入数据库和 Redis）
 * 2. 查询在线志愿者列表（优先从 Redis 读，Redis 无数据时降级查数据库）
 *
 * 【为什么要同时写数据库和 Redis？】
 * - Redis：读写速度快，适合高频实时查询（匹配算法用）
 * - 数据库：持久化存储，Redis 重启后数据不丢失
 *
 * 【Redis key 设计】
 * key:   vol:loc:{userId}
 * value: JSON {"lat": 39.9, "lng": 116.4, "isOnline": true}
 * TTL:   30 秒（超过30秒未更新，key 自动过期，视为离线）
 */
@Slf4j
@Service
public class VolunteerLocationService {

    private final VolunteerLocationRepository locationRepository;
    private final UserRepository userRepository;
    private final StringRedisTemplate redisTemplate;
    private final ObjectMapper objectMapper;

    /** Redis key 前缀 */
    private static final String REDIS_KEY_PREFIX = "vol:loc:";

    /** 志愿者位置 Redis TTL（秒） */
    @Value("${app.volunteer.location-ttl-seconds:30}")
    private long locationTtlSeconds;

    public VolunteerLocationService(VolunteerLocationRepository locationRepository,
                                     UserRepository userRepository,
                                     StringRedisTemplate redisTemplate,
                                     ObjectMapper objectMapper) {
        this.locationRepository = locationRepository;
        this.userRepository = userRepository;
        this.redisTemplate = redisTemplate;
        this.objectMapper = objectMapper;
    }

    /**
     * 更新志愿者位置
     *
     * 【流程】
     * 1. 查数据库是否已有该志愿者的位置记录
     * 2. 有 → 更新，没有 → 新建
     * 3. 同时写入 Redis（设 TTL 30秒）
     *
     * @param userId   志愿者用户ID
     * @param latitude 纬度
     * @param longitude 经度
     * @param isOnline  是否在线
     */
    public void updateLocation(Long userId, Double latitude, Double longitude, Boolean isOnline) {
        // 1. 更新数据库（UPSERT 逻辑）
        VolunteerLocation location = locationRepository.findByVolunteerId(userId)
                .orElseGet(() -> {
                    // 不存在则新建
                    VolunteerLocation newLoc = new VolunteerLocation();
                    User volunteer = userRepository.getReferenceById(userId);
                    newLoc.setVolunteer(volunteer);
                    return newLoc;
                });

        location.setLatitude(latitude);
        location.setLongitude(longitude);
        location.setIsOnline(isOnline != null ? isOnline : true);
        location.setUpdatedAt(LocalDateTime.now());
        locationRepository.save(location);

        // 2. 写入 Redis
        try {
            String key = REDIS_KEY_PREFIX + userId;
            Map<String, Object> value = new HashMap<>();
            value.put("userId", userId);
            value.put("lat", latitude);
            value.put("lng", longitude);
            value.put("isOnline", isOnline != null ? isOnline : true);
            value.put("updatedAt", System.currentTimeMillis());

            String json = objectMapper.writeValueAsString(value);
            redisTemplate.opsForValue().set(key, json, locationTtlSeconds, TimeUnit.SECONDS);

            log.debug("志愿者 {} 位置已更新: lat={}, lng={}", userId, latitude, longitude);
        } catch (Exception e) {
            // Redis 写入失败不影响主流程，记录警告日志
            log.warn("Redis 写入志愿者 {} 位置失败: {}", userId, e.getMessage());
        }
    }

    /**
     * 获取所有在线志愿者的位置信息
     *
     * 【策略】
     * 1. 先查 Redis（速度快）
     * 2. Redis 无数据时，降级查数据库
     *
     * @return 在线志愿者位置列表，每项包含 userId、latitude、longitude
     */
    public List<Map<String, Object>> getOnlineVolunteerLocations() {
        // 1. 先查 Redis
        Set<String> keys = redisTemplate.keys(REDIS_KEY_PREFIX + "*");
        if (keys != null && !keys.isEmpty()) {
            List<Map<String, Object>> result = new ArrayList<>();
            for (String key : keys) {
                try {
                    String json = redisTemplate.opsForValue().get(key);
                    if (json != null) {
                        @SuppressWarnings("unchecked")
                        Map<String, Object> data = objectMapper.readValue(json, Map.class);
                        // 只返回在线的志愿者
                        if (Boolean.TRUE.equals(data.get("isOnline"))) {
                            result.add(data);
                        }
                    }
                } catch (Exception e) {
                    log.warn("解析 Redis 志愿者位置数据失败: {}", e.getMessage());
                }
            }
            if (!result.isEmpty()) {
                log.debug("从 Redis 获取到 {} 名在线志愿者", result.size());
                return result;
            }
        }

        // 2. Redis 无数据，降级查数据库
        log.info("Redis 无在线志愿者数据，降级查询数据库");
        List<VolunteerLocation> dbLocations = locationRepository.findByIsOnlineTrue();
        List<Map<String, Object>> result = new ArrayList<>();
        for (VolunteerLocation loc : dbLocations) {
            Map<String, Object> data = new HashMap<>();
            data.put("userId", loc.getVolunteer().getId());
            data.put("lat", loc.getLatitude());
            data.put("lng", loc.getLongitude());
            data.put("isOnline", true);
            result.add(data);
        }

        log.debug("从数据库获取到 {} 名在线志愿者", result.size());
        return result;
    }
}
