package com.example.demo.service;

import com.example.demo.dto.CreateOrderRequest;
import com.example.demo.dto.OrderResponse;
import com.example.demo.entity.CancelledBy;
import com.example.demo.entity.OrderStatus;
import com.example.demo.entity.RunOrder;
import com.example.demo.entity.VolunteerProfile;
import com.example.demo.event.OrderCreatedEvent;
import com.example.demo.exception.DuplicateOrderException;
import com.example.demo.exception.OrderNotFoundException;
import com.example.demo.exception.OrderPermissionException;
import com.example.demo.exception.OrderStatusException;
import com.example.demo.repository.RunOrderRepository;
import com.example.demo.repository.UserRepository;
import com.example.demo.repository.VolunteerProfileRepository;
import com.example.demo.util.GeoUtils;
import com.example.demo.util.PhoneMaskUtils;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * 订单业务逻辑服务 —— 处理订单的创建、接单、拒单、完成、取消
 */
@Slf4j
@Service
public class OrderService {

    private final RunOrderRepository runOrderRepository;
    private final UserRepository userRepository;
    private final ApplicationEventPublisher eventPublisher;
    private final VolunteerProfileRepository volunteerProfileRepository;

    @Value("${app.matching.max-distance-km:10}")
    private double maxDistanceKm;

    public OrderService(RunOrderRepository runOrderRepository,
                        UserRepository userRepository,
                        ApplicationEventPublisher eventPublisher,
                        VolunteerProfileRepository volunteerProfileRepository) {
        this.runOrderRepository = runOrderRepository;
        this.userRepository = userRepository;
        this.eventPublisher = eventPublisher;
        this.volunteerProfileRepository = volunteerProfileRepository;
    }

    /**
     * 创建订单
     *
     * @param blindUserId 盲人用户ID（从 JWT 中解析）
     * @param request     创建订单请求
     * @return OrderResponse 包含订单ID、状态和提示信息
     */
    @Transactional
    public OrderResponse createOrder(Long blindUserId, CreateOrderRequest request) {
        // 1. 校验时间：结束时间必须大于开始时间
        if (!request.getPlannedEndTime().isAfter(request.getPlannedStartTime())) {
            throw new IllegalArgumentException("计划结束时间必须晚于开始时间");
        }

        // 2. 校验时间：开始时间不能早于当前时间
        if (!request.getPlannedStartTime().isAfter(LocalDateTime.now())) {
            throw new IllegalArgumentException("计划开始时间不能早于当前时间");
        }

        // 3. 校验重复订单：同一用户不能有进行中的订单
        boolean hasActiveOrder = runOrderRepository.existsByBlindUserIdAndStatusIn(
                blindUserId,
                List.of(OrderStatus.PENDING_MATCH, OrderStatus.PENDING_ACCEPT, OrderStatus.IN_PROGRESS)
        );
        if (hasActiveOrder) {
            throw new DuplicateOrderException("您有进行中的订单，请完成后再下单");
        }

        // 4. 创建并保存订单
        RunOrder order = new RunOrder();
        order.setBlindUser(userRepository.getReferenceById(blindUserId));
        order.setStartLatitude(request.getStartLatitude());
        order.setStartLongitude(request.getStartLongitude());
        order.setStartAddress(request.getStartAddress());
        order.setPlannedStartTime(request.getPlannedStartTime());
        order.setPlannedEndTime(request.getPlannedEndTime());
        order.setStatus(OrderStatus.PENDING_MATCH);

        RunOrder savedOrder = runOrderRepository.save(order);

        // 5. 发布订单创建事件 → 触发异步匹配流程
        eventPublisher.publishEvent(new OrderCreatedEvent(this, savedOrder));

        log.info("订单已创建，ID={}，盲人用户={}，状态=PENDING_MATCH", savedOrder.getId(), blindUserId);

        return new OrderResponse(savedOrder.getId(), savedOrder.getStatus(), "订单已提交，正在匹配志愿者");
    }

    /**
     * 志愿者接单
     *
     * @param orderId     订单ID
     * @param volunteerId 志愿者用户ID
     */
    @Transactional
    public void acceptOrder(Long orderId, Long volunteerId) {
        // 校验志愿者已认证
        VolunteerProfile profile = volunteerProfileRepository.findByUserId(volunteerId)
                .orElseThrow(() -> new OrderPermissionException("请先完成志愿者认证"));
        if (!Boolean.TRUE.equals(profile.getVerified())) {
            throw new OrderPermissionException("请先完成志愿者认证");
        }

        RunOrder order = runOrderRepository.findById(orderId)
                .orElseThrow(() -> new OrderNotFoundException("订单不存在，ID: " + orderId));

        if (order.getStatus() != OrderStatus.PENDING_ACCEPT) {
            throw new OrderStatusException("订单已被其他志愿者接单或已取消");
        }

        order.setVolunteer(userRepository.getReferenceById(volunteerId));
        order.setStatus(OrderStatus.IN_PROGRESS);
        order.setAcceptedAt(LocalDateTime.now());

        runOrderRepository.save(order);

        log.info("志愿者 {} 已接单，订单ID={}", volunteerId, orderId);
    }

    /**
     * 志愿者拒单 —— 本期只记录日志，不修改订单状态
     */
    public void rejectOrder(Long orderId, Long volunteerId) {
        log.info("志愿者 {} 拒绝了订单 {}", volunteerId, orderId);
    }

    /**
     * 志愿者结束服务
     *
     * @param orderId     订单ID
     * @param volunteerId 志愿者用户ID
     */
    @Transactional
    public void finishOrder(Long orderId, Long volunteerId) {
        RunOrder order = runOrderRepository.findById(orderId)
                .orElseThrow(() -> new OrderNotFoundException("订单不存在，ID: " + orderId));

        // 校验是接单的志愿者
        if (order.getVolunteer() == null || !order.getVolunteer().getId().equals(volunteerId)) {
            throw new OrderPermissionException("只有接单的志愿者才能结束服务");
        }

        if (order.getStatus() != OrderStatus.IN_PROGRESS) {
            throw new OrderStatusException("订单不在服务中状态");
        }

        order.setStatus(OrderStatus.COMPLETED);
        order.setFinishedAt(LocalDateTime.now());

        runOrderRepository.save(order);

        log.info("志愿者 {} 结束了订单 {}，订单完成", volunteerId, orderId);
    }

    /**
     * 取消订单 —— 盲人或志愿者均可取消，但规则不同
     *
     * 盲人：可取消 PENDING_MATCH / PENDING_ACCEPT，IN_PROGRESS 阶段不能取消
     * 志愿者：可取消 PENDING_ACCEPT / IN_PROGRESS（IN_PROGRESS 取消视为爽约）
     *
     * @param orderId 订单ID
     * @param userId  操作用户ID（可能是盲人或志愿者）
     */
    @Transactional
    public void cancelOrder(Long orderId, Long userId) {
        RunOrder order = runOrderRepository.findById(orderId)
                .orElseThrow(() -> new OrderNotFoundException("订单不存在，ID: " + orderId));

        boolean isBlind = order.getBlindUser().getId().equals(userId);
        boolean isVolunteer = order.getVolunteer() != null && order.getVolunteer().getId().equals(userId);

        if (!isBlind && !isVolunteer) {
            throw new OrderPermissionException("您无权操作此订单");
        }

        OrderStatus status = order.getStatus();

        if (isBlind) {
            // 盲人：只能取消 PENDING_MATCH 和 PENDING_ACCEPT
            if (status == OrderStatus.IN_PROGRESS) {
                throw new OrderPermissionException("服务进行中，如需结束请联系志愿者");
            }
            if (status != OrderStatus.PENDING_MATCH && status != OrderStatus.PENDING_ACCEPT) {
                throw new OrderStatusException("当前订单状态不允许取消");
            }
            order.setCancelledBy(CancelledBy.BLIND);
        } else {
            // 志愿者：可取消 PENDING_ACCEPT 和 IN_PROGRESS
            if (status != OrderStatus.PENDING_ACCEPT && status != OrderStatus.IN_PROGRESS) {
                throw new OrderStatusException("当前订单状态不允许取消");
            }
            order.setCancelledBy(CancelledBy.VOLUNTEER);
        }

        order.setStatus(OrderStatus.CANCELLED);

        runOrderRepository.save(order);

        log.info("订单 {} 已取消，取消方={}，原状态={}", orderId, order.getCancelledBy(), status);
    }

    /**
     * 查询订单详情（需校验权限）
     *
     * @param orderId 订单ID
     * @param userId  当前用户ID
     * @return 订单实体
     */
    public RunOrder getOrder(Long orderId, Long userId) {
        RunOrder order = runOrderRepository.findByIdWithBlindUser(orderId)
                .orElseThrow(() -> new OrderNotFoundException("订单不存在，ID: " + orderId));

        boolean isBlind = order.getBlindUser().getId().equals(userId);
        boolean isVolunteer = order.getVolunteer() != null && order.getVolunteer().getId().equals(userId);

        if (!isBlind && !isVolunteer) {
            throw new OrderPermissionException("您无权查看此订单");
        }

        return order;
    }

    /**
     * 查询附近可接订单列表（志愿者视角）
     *
     * @param volunteerId  志愿者用户ID
     * @param volunteerLat 志愿者纬度
     * @param volunteerLng 志愿者经度
     * @return 附近可接订单列表，按距离升序
     */
    public List<AvailableOrderResponse> getAvailableOrders(Long volunteerId, double volunteerLat, double volunteerLng) {
        List<RunOrder> pendingOrders = runOrderRepository.findByStatus(OrderStatus.PENDING_ACCEPT);

        List<AvailableOrderResponse> result = new ArrayList<>();
        for (RunOrder order : pendingOrders) {
            double distance = GeoUtils.distanceKm(
                    volunteerLat, volunteerLng,
                    order.getStartLatitude(), order.getStartLongitude()
            );
            if (distance <= maxDistanceKm) {
                result.add(new AvailableOrderResponse(
                        order.getId(),
                        order.getStartAddress(),
                        Math.round(distance * 10.0) / 10.0,
                        order.getPlannedStartTime(),
                        order.getPlannedEndTime(),
                        PhoneMaskUtils.mask(order.getBlindUser().getPhone())
                ));
            }
        }

        result.sort((a, b) -> Double.compare(a.distanceKm(), b.distanceKm()));
        return result.stream().limit(20).toList();
    }

    /**
     * 附近可接订单响应 record
     */
    public record AvailableOrderResponse(Long orderId, String startAddress, double distanceKm,
                                          LocalDateTime plannedStart, LocalDateTime plannedEnd,
                                          String blindUserPhone) {}
}
