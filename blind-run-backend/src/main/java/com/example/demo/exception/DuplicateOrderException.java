package com.example.demo.exception;

/**
 * 重复订单异常 —— 当用户已有进行中的订单却再次下单时抛出
 *
 * 【什么时候会抛出这个异常？】
 * 同一个盲人用户在已有 PENDING_MATCH 或 PENDING_ACCEPT 状态的订单时，
 * 再次调用创建订单接口。
 * GlobalExceptionHandler 会捕获它并返回 HTTP 409 Conflict。
 */
public class DuplicateOrderException extends RuntimeException {
    public DuplicateOrderException(String message) {
        super(message);
    }
}
