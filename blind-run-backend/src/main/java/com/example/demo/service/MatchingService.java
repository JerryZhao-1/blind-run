package com.example.demo.service;

import com.example.demo.entity.OrderStatus;
import com.example.demo.entity.RunOrder;
import com.example.demo.event.OrderCreatedEvent;
import com.example.demo.repository.RunOrderRepository;
import com.example.demo.util.GeoUtils;
import com.example.demo.util.PhoneMaskUtils;
import com.example.demo.websocket.VolunteerSessionRegistry;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.event.EventListener;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;

import java.util.*;
import java.util.stream.Collectors;

/**
 * 匹配服务 —— 监听订单创建事件，异步执行距离匹配并推送通知
 *
 * 【整体流程】
 * 1. 盲人创建订单 → 发布 OrderCreatedEvent
 * 2. 本服务监听到事件 → 获取在线志愿者列表
 * 3. 计算每个志愿者到起跑点的距离
 * 4. 过滤距离超出阈值的志愿者
 * 5. 按距离排序，取前 N 名
 * 6. 通过 WebSocket 向候选志愿者推送订单信息
 * 7. 更新订单状态为 PENDING_ACCEPT
 *
 * 【为什么用 @Async？】
 * 匹配过程涉及网络查询（Redis）和计算，可能需要几百毫秒。
 * 用 @Async 让匹配在独立线程中执行，不阻塞用户下单的响应。
 * 用户下单后立即收到 "订单已提交" 的响应，匹配在后台默默进行。
 */
@Slf4j
@Component
public class MatchingService {

    private final VolunteerLocationService volunteerLocationService;
    private final VolunteerSessionRegistry sessionRegistry;
    private final RunOrderRepository runOrderRepository;
    private final ObjectMapper objectMapper;

    /** 匹配最大距离（公里），从配置文件读取 */
    @Value("${app.matching.max-distance-km:10}")
    private double maxDistanceKm;

    /** 最多推送给几名志愿者，从配置文件读取 */
    @Value("${app.matching.max-candidates:3}")
    private int maxCandidates;

    public MatchingService(VolunteerLocationService volunteerLocationService,
                           VolunteerSessionRegistry sessionRegistry,
                           RunOrderRepository runOrderRepository,
                           ObjectMapper objectMapper) {
        this.volunteerLocationService = volunteerLocationService;
        this.sessionRegistry = sessionRegistry;
        this.runOrderRepository = runOrderRepository;
        this.objectMapper = objectMapper;
    }

    /**
     * 监听订单创建事件，异步执行匹配
     *
     * @EventListener  标记这是一个事件监听器，当有 OrderCreatedEvent 发布时自动调用
     * @Async          在独立线程中执行，不阻塞事件发布者
     */
    @EventListener
    @Async
    public void handleOrderCreated(OrderCreatedEvent event) {
        // 从数据库重新加载订单（JOIN FETCH 盲人用户），避免异步线程中懒加载异常
        RunOrder order = runOrderRepository.findByIdWithBlindUser(event.getOrder().getId()).orElse(null);
        if (order == null) {
            log.warn("订单 {} 未找到，跳过匹配", event.getOrder().getId());
            return;
        }
        log.info("开始匹配订单 {}，起跑点: ({}, {})",
                order.getId(), order.getStartLatitude(), order.getStartLongitude());

        // 1. 获取所有在线志愿者位置
        List<Map<String, Object>> onlineVolunteers = volunteerLocationService.getOnlineVolunteerLocations();
        if (onlineVolunteers.isEmpty()) {
            log.info("没有在线志愿者，订单 {} 维持 PENDING_MATCH 状态", order.getId());
            return;
        }

        // 2. 计算距离并过滤
        List<VolunteerCandidate> candidates = new ArrayList<>();
        for (Map<String, Object> vol : onlineVolunteers) {
            Long volunteerId = ((Number) vol.get("userId")).longValue();
            double volLat = ((Number) vol.get("lat")).doubleValue();
            double volLng = ((Number) vol.get("lng")).doubleValue();

            double distance = GeoUtils.distanceKm(
                    order.getStartLatitude(), order.getStartLongitude(),
                    volLat, volLng
            );

            if (distance <= maxDistanceKm) {
                candidates.add(new VolunteerCandidate(volunteerId, distance));
            }
        }

        // 3. 按距离排序，取前 N 名
        candidates.sort(Comparator.comparingDouble(VolunteerCandidate::getDistance));
        List<VolunteerCandidate> selected = candidates.stream()
                .limit(maxCandidates)
                .collect(Collectors.toList());

        if (selected.isEmpty()) {
            log.info("订单 {}：{} 名在线志愿者中无人距离在 {}km 以内",
                    order.getId(), onlineVolunteers.size(), maxDistanceKm);
            return;
        }

        // 4. 推送订单信息给候选志愿者
        for (VolunteerCandidate candidate : selected) {
            pushOrderToVolunteer(order, candidate.getVolunteerId(), candidate.getDistance());
        }

        // 5. 更新订单状态为 PENDING_ACCEPT
        if (order.getStatus() == OrderStatus.PENDING_MATCH) {
            order.setStatus(OrderStatus.PENDING_ACCEPT);
            runOrderRepository.save(order);
            log.info("订单 {} 状态更新为 PENDING_ACCEPT，已推送给 {} 名志愿者",
                    order.getId(), selected.size());
        }
    }

    /**
     * 通过 WebSocket 向志愿者推送新订单通知
     *
     * 推送消息格式（JSON）：
     * {
     *   "type": "NEW_ORDER",
     *   "orderId": 1001,
     *   "blindUserPhone": "138****1234",
     *   "startAddress": "朝阳公园南门",
     *   "distanceKm": 1.8,
     *   "plannedStart": "2025-04-02T18:00:00",
     *   "plannedEnd": "2025-04-02T19:00:00"
     * }
     */
    private void pushOrderToVolunteer(RunOrder order, Long volunteerId, double distanceKm) {
        try {
            Map<String, Object> message = new LinkedHashMap<>();
            message.put("type", "NEW_ORDER");
            message.put("orderId", order.getId());

            // 手机号脱敏
            String maskedPhone = PhoneMaskUtils.mask(order.getBlindUser().getPhone());
            message.put("blindUserPhone", maskedPhone);

            message.put("startAddress", order.getStartAddress());
            message.put("distanceKm", Math.round(distanceKm * 10.0) / 10.0); // 保留1位小数
            message.put("plannedStart", order.getPlannedStartTime().toString());
            message.put("plannedEnd", order.getPlannedEndTime().toString());

            String json = objectMapper.writeValueAsString(message);
            sessionRegistry.sendToUser(volunteerId, json);

            log.info("已向志愿者 {} 推送订单 {}，距离 {}km", volunteerId, order.getId(),
                    String.format("%.1f", distanceKm));
        } catch (Exception e) {
            log.warn("推送订单 {} 给志愿者 {} 失败: {}", order.getId(), volunteerId, e.getMessage());
        }
    }

    /**
     * 内部类：志愿者候选人的距离信息
     * 用于排序和筛选
     */
    private static class VolunteerCandidate {
        private final Long volunteerId;
        private final double distance;

        public VolunteerCandidate(Long volunteerId, double distance) {
            this.volunteerId = volunteerId;
            this.distance = distance;
        }

        public Long getVolunteerId() { return volunteerId; }
        public double getDistance() { return distance; }
    }
}
