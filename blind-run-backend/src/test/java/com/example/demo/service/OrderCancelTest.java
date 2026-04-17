package com.example.demo.service;

import com.example.demo.entity.*;
import com.example.demo.exception.OrderPermissionException;

import com.example.demo.repository.RunOrderRepository;
import com.example.demo.repository.UserRepository;
import com.example.demo.repository.VolunteerProfileRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.context.ApplicationEventPublisher;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

/**
 * 订单取消测试 —— 验证取消逻辑的身份判断和状态规则
 */
@ExtendWith(MockitoExtension.class)
class OrderCancelTest {

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

    /** 盲人在 IN_PROGRESS 状态取消 → 403 */
    @Test
    void testBlindCancelInProgress() {
        User blindUser = new User();
        blindUser.setId(1L);

        User volunteer = new User();
        volunteer.setId(2L);

        RunOrder order = new RunOrder();
        order.setId(1001L);
        order.setBlindUser(blindUser);
        order.setVolunteer(volunteer);
        order.setStatus(OrderStatus.IN_PROGRESS);

        when(runOrderRepository.findById(1001L)).thenReturn(Optional.of(order));

        OrderPermissionException ex = assertThrows(OrderPermissionException.class,
                () -> orderService.cancelOrder(1001L, 1L));
        assertTrue(ex.getMessage().contains("服务进行中"));
    }

    /** 志愿者取消他人订单 → 403 */
    @Test
    void testStrangerCancel() {
        User blindUser = new User();
        blindUser.setId(1L);

        RunOrder order = new RunOrder();
        order.setId(1001L);
        order.setBlindUser(blindUser);
        order.setStatus(OrderStatus.PENDING_MATCH);

        when(runOrderRepository.findById(1001L)).thenReturn(Optional.of(order));

        assertThrows(OrderPermissionException.class,
                () -> orderService.cancelOrder(1001L, 99L));
    }

    /** 盲人在 PENDING_MATCH 取消 → 成功 */
    @Test
    void testBlindCancelPendingMatch() {
        User blindUser = new User();
        blindUser.setId(1L);

        RunOrder order = new RunOrder();
        order.setId(1001L);
        order.setBlindUser(blindUser);
        order.setStatus(OrderStatus.PENDING_MATCH);

        when(runOrderRepository.findById(1001L)).thenReturn(Optional.of(order));
        when(runOrderRepository.save(any(RunOrder.class))).thenReturn(order);

        orderService.cancelOrder(1001L, 1L);

        assertEquals(OrderStatus.CANCELLED, order.getStatus());
        assertEquals(CancelledBy.BLIND, order.getCancelledBy());
    }

    /** 盲人在 PENDING_ACCEPT 取消 → 成功 */
    @Test
    void testBlindCancelPendingAccept() {
        User blindUser = new User();
        blindUser.setId(1L);

        RunOrder order = new RunOrder();
        order.setId(1001L);
        order.setBlindUser(blindUser);
        order.setStatus(OrderStatus.PENDING_ACCEPT);

        when(runOrderRepository.findById(1001L)).thenReturn(Optional.of(order));
        when(runOrderRepository.save(any(RunOrder.class))).thenReturn(order);

        orderService.cancelOrder(1001L, 1L);

        assertEquals(OrderStatus.CANCELLED, order.getStatus());
        assertEquals(CancelledBy.BLIND, order.getCancelledBy());
    }

    /** 志愿者在 IN_PROGRESS 取消 → 成功（爽约） */
    @Test
    void testVolunteerCancelInProgress() {
        User blindUser = new User();
        blindUser.setId(1L);

        User volunteer = new User();
        volunteer.setId(2L);

        RunOrder order = new RunOrder();
        order.setId(1001L);
        order.setBlindUser(blindUser);
        order.setVolunteer(volunteer);
        order.setStatus(OrderStatus.IN_PROGRESS);

        when(runOrderRepository.findById(1001L)).thenReturn(Optional.of(order));
        when(runOrderRepository.save(any(RunOrder.class))).thenReturn(order);

        orderService.cancelOrder(1001L, 2L);

        assertEquals(OrderStatus.CANCELLED, order.getStatus());
        assertEquals(CancelledBy.VOLUNTEER, order.getCancelledBy());
    }

    /** 志愿者在 PENDING_ACCEPT 取消 → 成功 */
    @Test
    void testVolunteerCancelPendingAccept() {
        User blindUser = new User();
        blindUser.setId(1L);

        User volunteer = new User();
        volunteer.setId(2L);

        RunOrder order = new RunOrder();
        order.setId(1001L);
        order.setBlindUser(blindUser);
        order.setVolunteer(volunteer);
        order.setStatus(OrderStatus.PENDING_ACCEPT);

        when(runOrderRepository.findById(1001L)).thenReturn(Optional.of(order));
        when(runOrderRepository.save(any(RunOrder.class))).thenReturn(order);

        orderService.cancelOrder(1001L, 2L);

        assertEquals(OrderStatus.CANCELLED, order.getStatus());
        assertEquals(CancelledBy.VOLUNTEER, order.getCancelledBy());
    }
}
