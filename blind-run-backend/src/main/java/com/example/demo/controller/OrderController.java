package com.example.demo.controller;

import com.example.demo.dto.CreateOrderRequest;
import com.example.demo.dto.OrderDetailResponse;
import com.example.demo.dto.OrderResponse;
import com.example.demo.entity.OrderStatus;
import com.example.demo.entity.RunOrder;
import com.example.demo.repository.RunOrderRepository;
import com.example.demo.service.OrderService;
import com.example.demo.service.VolunteerLocationService;
import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import com.example.demo.util.PhoneMaskUtils;

import java.util.List;
import java.util.Map;

/**
 * 订单控制器 —— 处理订单相关的 HTTP 请求
 *
 * POST   /api/orders              → 盲人创建订单
 * POST   /api/orders/{id}/accept  → 志愿者接单
 * POST   /api/orders/{id}/reject  → 志愿者拒单
 * POST   /api/orders/{id}/finish  → 志愿者结束服务
 * POST   /api/orders/{id}/cancel  → 取消订单
 * GET    /api/orders/{id}         → 查询订单详情
 * GET    /api/orders/mine         → 查询我的订单列表
 */
@RestController
@RequestMapping("/api/orders")
public class OrderController {

    private final OrderService orderService;
    private final RunOrderRepository runOrderRepository;
    private final VolunteerLocationService volunteerLocationService;

    public OrderController(OrderService orderService, RunOrderRepository runOrderRepository,
                           VolunteerLocationService volunteerLocationService) {
        this.orderService = orderService;
        this.runOrderRepository = runOrderRepository;
        this.volunteerLocationService = volunteerLocationService;
    }

    @PostMapping
    public ResponseEntity<OrderResponse> createOrder(@Valid @RequestBody CreateOrderRequest request) {
        Long userId = (Long) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        OrderResponse response = orderService.createOrder(userId, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @PostMapping("/{id}/accept")
    public ResponseEntity<?> acceptOrder(@PathVariable Long id) {
        Long userId = (Long) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        orderService.acceptOrder(id, userId);
        return ResponseEntity.ok(Map.of("success", true, "orderId", id));
    }

    @PostMapping("/{id}/reject")
    public ResponseEntity<?> rejectOrder(@PathVariable Long id) {
        Long userId = (Long) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        orderService.rejectOrder(id, userId);
        return ResponseEntity.ok(Map.of("success", true));
    }

    @PostMapping("/{id}/finish")
    public ResponseEntity<?> finishOrder(@PathVariable Long id) {
        Long userId = (Long) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        orderService.finishOrder(id, userId);
        return ResponseEntity.ok(Map.of("success", true, "orderId", id));
    }

    @PostMapping("/{id}/cancel")
    public ResponseEntity<?> cancelOrder(@PathVariable Long id) {
        Long userId = (Long) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        orderService.cancelOrder(id, userId);
        return ResponseEntity.ok(Map.of("success", true));
    }

    @GetMapping("/available")
    public ResponseEntity<?> getAvailableOrders() {
        Long userId = (Long) SecurityContextHolder.getContext().getAuthentication().getPrincipal();

        // 获取志愿者最新位置
        double lat = 0, lng = 0;
        boolean hasLocation = false;
        for (var loc : volunteerLocationService.getOnlineVolunteerLocations()) {
            if (((Number) loc.get("userId")).longValue() == userId) {
                lat = ((Number) loc.get("lat")).doubleValue();
                lng = ((Number) loc.get("lng")).doubleValue();
                hasLocation = true;
                break;
            }
        }
        if (!hasLocation) {
            return ResponseEntity.ok(List.of());
        }

        List<OrderService.AvailableOrderResponse> orders = orderService.getAvailableOrders(userId, lat, lng);
        return ResponseEntity.ok(orders);
    }

    @GetMapping("/{id}")
    public ResponseEntity<OrderDetailResponse> getOrder(@PathVariable Long id) {
        Long userId = (Long) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        RunOrder order = orderService.getOrder(id, userId);
        return ResponseEntity.ok(toDetailResponse(order));
    }

    @GetMapping("/mine")
    public ResponseEntity<Page<OrderDetailResponse>> getMyOrders(
            @RequestParam String role,
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {

        Long userId = (Long) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<RunOrder> orders;

        if ("BLIND".equalsIgnoreCase(role)) {
            if (status != null) {
                orders = runOrderRepository.findByBlindUserIdAndStatusIn(
                        userId, List.of(OrderStatus.valueOf(status)), pageable);
            } else {
                orders = runOrderRepository.findByBlindUserId(userId, pageable);
            }
        } else if ("VOLUNTEER".equalsIgnoreCase(role)) {
            if (status != null) {
                orders = runOrderRepository.findByVolunteerIdAndStatusIn(
                        userId, List.of(OrderStatus.valueOf(status)), pageable);
            } else {
                orders = runOrderRepository.findByVolunteerId(userId, pageable);
            }
        } else {
            return ResponseEntity.badRequest().build();
        }

        return ResponseEntity.ok(orders.map(this::toDetailResponse));
    }

    /** 将 RunOrder 实体转换为 OrderDetailResponse DTO */
    private OrderDetailResponse toDetailResponse(RunOrder order) {
        String volunteerPhone = order.getVolunteer() != null ? PhoneMaskUtils.mask(order.getVolunteer().getPhone()) : null;
        return new OrderDetailResponse(
                order.getId(),
                order.getStatus(),
                order.getStartAddress(),
                order.getPlannedStartTime(),
                order.getPlannedEndTime(),
                volunteerPhone,
                order.getAcceptedAt(),
                order.getCreatedAt()
        );
    }
}
