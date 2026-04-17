package com.example.demo.service;

import com.example.demo.entity.OrderStatus;
import com.example.demo.entity.RunOrder;
import com.example.demo.entity.User;
import com.example.demo.event.OrderCreatedEvent;
import com.example.demo.repository.RunOrderRepository;
import com.example.demo.websocket.VolunteerSessionRegistry;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.*;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * MatchingService 单元测试 —— 验证匹配算法的逻辑
 */
@ExtendWith(MockitoExtension.class)
class MatchingServiceTest {

    @Mock
    private VolunteerLocationService volunteerLocationService;

    @Mock
    private VolunteerSessionRegistry sessionRegistry;

    @Mock
    private RunOrderRepository runOrderRepository;

    private ObjectMapper objectMapper = new ObjectMapper();

    private MatchingService matchingService;

    @BeforeEach
    void setUp() {
        matchingService = new MatchingService(
                volunteerLocationService, sessionRegistry, runOrderRepository, objectMapper
        );
        try {
            var maxDistField = MatchingService.class.getDeclaredField("maxDistanceKm");
            maxDistField.setAccessible(true);
            maxDistField.set(matchingService, 10.0);

            var maxCandField = MatchingService.class.getDeclaredField("maxCandidates");
            maxCandField.setAccessible(true);
            maxCandField.set(matchingService, 3);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

    /** 5名志愿者，距离0.5/1.1/3.3/8.0/11.8km → 应推送给前3名（第5名超出10km被过滤） */
    @Test
    void testMatchingWithMixedDistances() {
        RunOrder order = new RunOrder();
        order.setId(1001L);
        order.setStartLatitude(39.9340);
        order.setStartLongitude(116.4740);
        order.setStartAddress("朝阳公园南门");
        order.setPlannedStartTime(LocalDateTime.now().plusHours(1));
        order.setPlannedEndTime(LocalDateTime.now().plusHours(2));
        order.setStatus(OrderStatus.PENDING_MATCH);

        User blindUser = new User();
        blindUser.setPhone("13812345678");
        order.setBlindUser(blindUser);

        List<Map<String, Object>> volunteers = new ArrayList<>();
        volunteers.add(createVolunteer(1L, 39.9385, 116.4740));  // ~0.5km
        volunteers.add(createVolunteer(2L, 39.9440, 116.4740));  // ~1.1km
        volunteers.add(createVolunteer(3L, 39.9640, 116.4740));  // ~3.3km
        volunteers.add(createVolunteer(4L, 40.0060, 116.4740));  // ~8.0km
        volunteers.add(createVolunteer(5L, 40.0400, 116.4740));  // ~11.8km（超出10km）

        when(volunteerLocationService.getOnlineVolunteerLocations()).thenReturn(volunteers);
        when(runOrderRepository.findByIdWithBlindUser(1001L)).thenReturn(Optional.of(order));

        matchingService.handleOrderCreated(new OrderCreatedEvent(this, order));

        verify(sessionRegistry, times(3)).sendToUser(anyLong(), anyString());
        assertEquals(OrderStatus.PENDING_ACCEPT, order.getStatus());
    }

    /** 没有在线志愿者时，订单状态维持 PENDING_MATCH */
    @Test
    void testNoOnlineVolunteers() {
        RunOrder order = new RunOrder();
        order.setId(1002L);
        order.setStartLatitude(39.9340);
        order.setStartLongitude(116.4740);
        order.setStatus(OrderStatus.PENDING_MATCH);

        User blindUser = new User();
        blindUser.setPhone("13812345678");
        order.setBlindUser(blindUser);

        when(volunteerLocationService.getOnlineVolunteerLocations()).thenReturn(Collections.emptyList());
        when(runOrderRepository.findByIdWithBlindUser(1002L)).thenReturn(Optional.of(order));

        matchingService.handleOrderCreated(new OrderCreatedEvent(this, order));

        verify(sessionRegistry, never()).sendToUser(anyLong(), anyString());
        assertEquals(OrderStatus.PENDING_MATCH, order.getStatus());
    }

    private Map<String, Object> createVolunteer(Long userId, double lat, double lng) {
        Map<String, Object> vol = new HashMap<>();
        vol.put("userId", userId);
        vol.put("lat", lat);
        vol.put("lng", lng);
        vol.put("isOnline", true);
        return vol;
    }
}
