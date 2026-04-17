package com.example.demo.exception;

/**
 * 订单状态异常 —— 当订单状态流转不合法时抛出
 *
 * 例如：接单时订单状态不是 PENDING_ACCEPT，或结束服务时订单不在 IN_PROGRESS 状态
 * GlobalExceptionHandler 会捕获它并返回 HTTP 409。
 */
public class OrderStatusException extends RuntimeException {
    public OrderStatusException(String message) {
        super(message);
    }
}
