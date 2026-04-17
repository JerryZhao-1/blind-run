package com.example.demo.dto;

import com.example.demo.entity.OrderStatus;
import lombok.AllArgsConstructor;
import lombok.Data;

/**
 * 订单创建响应 DTO —— 创建订单成功后返回给前端的数据
 *
 * 【字段说明】
 * id      订单ID（前端可以用它查询订单状态）
 * status  订单当前状态
 * message 提示信息
 */
@Data
@AllArgsConstructor
public class OrderResponse {
    private Long id;
    private OrderStatus status;
    private String message;
}
