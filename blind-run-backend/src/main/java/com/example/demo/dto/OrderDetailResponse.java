package com.example.demo.dto;

import com.example.demo.entity.OrderStatus;
import lombok.AllArgsConstructor;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 订单详情响应 DTO —— 查询单个订单时返回
 */
@Data
@AllArgsConstructor
public class OrderDetailResponse {
    private Long orderId;
    private OrderStatus status;
    private String startAddress;
    private LocalDateTime plannedStart;
    private LocalDateTime plannedEnd;
    private String volunteerPhone;
    private LocalDateTime acceptedAt;
    private LocalDateTime createdAt;
}
