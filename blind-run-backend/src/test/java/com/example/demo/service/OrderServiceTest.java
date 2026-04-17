package com.example.demo.service;

import com.example.demo.dto.CreateOrderRequest;
import com.example.demo.dto.OrderResponse;
import com.example.demo.entity.OrderStatus;
import com.example.demo.entity.RunOrder;
import com.example.demo.entity.User;
import com.example.demo.exception.DuplicateOrderException;
import com.example.demo.exception.OrderNotFoundException;
import com.example.demo.exception.OrderPermissionException;
import com.example.demo.exception.OrderStatusException;
import com.example.demo.repository.RunOrderRepository;
import com.example.demo.repository.UserRepository;
import com.example.demo.repository.VolunteerProfileRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.context.ApplicationEventPublisher;

import java.time.LocalDateTime;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * OrderService 单元测试 —— 验证订单创建和接单的业务逻辑
 */
@ExtendWith(MockitoExtension.class)
class OrderServiceTest {

    @Mock
    private RunOrderRepository runOrderRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private ApplicationEventPublisher eventPublisher;

    @Mock
    private VolunteerProfileRepository volunteerProfileRepository;

    private OrderService orderService;

    @BeforeEach
    void setUp() {
        orderService = new OrderService(runOrderRepository, userRepository, eventPublisher, volunteerProfileRepository);
    }

    /** 正常创建订单 */
    @Test
    void testCreateOrderSuccess() {
        CreateOrderRequest request = new CreateOrderRequest();
        request.setStartLatitude(39.9042);
        request.setStartLongitude(116.4074);
        request.setStartAddress("朝阳公园南门");
        request.setPlannedStartTime(LocalDateTime.now().plusHours(1));
        request.setPlannedEndTime(LocalDateTime.now().plusHours(2));

        when(runOrderRepository.existsByBlindUserIdAndStatusIn(anyLong(), anyList()))
                .thenReturn(false);
        when(runOrderRepository.save(any(RunOrder.class))).thenAnswer(invocation -> {
            RunOrder order = invocation.getArgument(0);
            order.setId(1001L);
            return order;
        });
        when(userRepository.getReferenceById(1L)).thenReturn(new User());

        OrderResponse response = orderService.createOrder(1L, request);

        assertEquals(1001L, response.getId());
        assertEquals(OrderStatus.PENDING_MATCH, response.getStatus());
        verify(eventPublisher).publishEvent(any());
    }

    /** 重复订单 */
    @Test
    void testCreateDuplicateOrder() {
        CreateOrderRequest request = new CreateOrderRequest();
        request.setStartLatitude(39.9042);
        request.setStartLongitude(116.4074);
        request.setStartAddress("朝阳公园南门");
        request.setPlannedStartTime(LocalDateTime.now().plusHours(1));
        request.setPlannedEndTime(LocalDateTime.now().plusHours(2));

        when(runOrderRepository.existsByBlindUserIdAndStatusIn(anyLong(), anyList()))
                .thenReturn(true);

        assertThrows(DuplicateOrderException.class, () -> orderService.createOrder(1L, request));
    }

    /** 结束时间早于开始时间 */
    @Test
    void testCreateOrderInvalidTime() {
        CreateOrderRequest request = new CreateOrderRequest();
        request.setStartLatitude(39.9042);
        request.setStartLongitude(116.4074);
        request.setStartAddress("朝阳公园南门");
        request.setPlannedStartTime(LocalDateTime.now().plusHours(2));
        request.setPlannedEndTime(LocalDateTime.now().plusHours(1));

        assertThrows(IllegalArgumentException.class, () -> orderService.createOrder(1L, request));
    }

    /** 开始时间早于当前时间 */
    @Test
    void testCreateOrderPastStartTime() {
        CreateOrderRequest request = new CreateOrderRequest();
        request.setStartLatitude(39.9042);
        request.setStartLongitude(116.4074);
        request.setStartAddress("朝阳公园南门");
        request.setPlannedStartTime(LocalDateTime.now().minusHours(1));
        request.setPlannedEndTime(LocalDateTime.now().plusHours(1));

        assertThrows(IllegalArgumentException.class, () -> orderService.createOrder(1L, request));
    }

    /** 接单成功 → IN_PROGRESS */
    @Test
    void testAcceptOrderSuccess() {
        RunOrder order = new RunOrder();
        order.setId(1001L);
        order.setStatus(OrderStatus.PENDING_ACCEPT);

        // 模拟已认证的志愿者
        com.example.demo.entity.VolunteerProfile profile = new com.example.demo.entity.VolunteerProfile();
        profile.setVerified(true);
        when(volunteerProfileRepository.findByUserId(2L)).thenReturn(Optional.of(profile));

        when(runOrderRepository.findById(1001L)).thenReturn(Optional.of(order));
        when(runOrderRepository.save(any(RunOrder.class))).thenReturn(order);
        when(userRepository.getReferenceById(2L)).thenReturn(new User());

        orderService.acceptOrder(1001L, 2L);

        assertEquals(OrderStatus.IN_PROGRESS, order.getStatus());
        assertNotNull(order.getAcceptedAt());
    }

    /** 接单失败：状态不是 PENDING_ACCEPT */
    @Test
    void testAcceptOrderWrongStatus() {
        com.example.demo.entity.VolunteerProfile profile = new com.example.demo.entity.VolunteerProfile();
        profile.setVerified(true);
        when(volunteerProfileRepository.findByUserId(2L)).thenReturn(Optional.of(profile));

        RunOrder order = new RunOrder();
        order.setId(1001L);
        order.setStatus(OrderStatus.PENDING_MATCH);

        when(runOrderRepository.findById(1001L)).thenReturn(Optional.of(order));

        assertThrows(OrderStatusException.class, () -> orderService.acceptOrder(1001L, 2L));
    }

    /** 接单失败：订单不存在 */
    @Test
    void testAcceptOrderNotFound() {
        com.example.demo.entity.VolunteerProfile profile = new com.example.demo.entity.VolunteerProfile();
        profile.setVerified(true);
        when(volunteerProfileRepository.findByUserId(2L)).thenReturn(Optional.of(profile));

        when(runOrderRepository.findById(999L)).thenReturn(Optional.empty());

        assertThrows(OrderNotFoundException.class, () -> orderService.acceptOrder(999L, 2L));
    }

    /** 结束服务成功 → COMPLETED */
    @Test
    void testFinishOrderSuccess() {
        User volunteer = new User();
        volunteer.setId(2L);

        RunOrder order = new RunOrder();
        order.setId(1001L);
        order.setStatus(OrderStatus.IN_PROGRESS);
        order.setVolunteer(volunteer);

        when(runOrderRepository.findById(1001L)).thenReturn(Optional.of(order));
        when(runOrderRepository.save(any(RunOrder.class))).thenReturn(order);

        orderService.finishOrder(1001L, 2L);

        assertEquals(OrderStatus.COMPLETED, order.getStatus());
        assertNotNull(order.getFinishedAt());
    }

    /** 结束服务失败：不是接单的志愿者 */
    @Test
    void testFinishOrderWrongVolunteer() {
        User volunteer = new User();
        volunteer.setId(2L);

        RunOrder order = new RunOrder();
        order.setId(1001L);
        order.setStatus(OrderStatus.IN_PROGRESS);
        order.setVolunteer(volunteer);

        when(runOrderRepository.findById(1001L)).thenReturn(Optional.of(order));

        assertThrows(OrderPermissionException.class, () -> orderService.finishOrder(1001L, 3L));
    }

    /** 结束服务失败：状态不是 IN_PROGRESS */
    @Test
    void testFinishOrderWrongStatus() {
        User volunteer = new User();
        volunteer.setId(2L);

        RunOrder order = new RunOrder();
        order.setId(1001L);
        order.setStatus(OrderStatus.PENDING_ACCEPT);
        order.setVolunteer(volunteer);

        when(runOrderRepository.findById(1001L)).thenReturn(Optional.of(order));

        assertThrows(OrderStatusException.class, () -> orderService.finishOrder(1001L, 2L));
    }
}
