package com.example.demo.exception;

/**
 * 订单不存在异常 —— 当查询的订单ID不存在时抛出
 *
 * 【什么时候会抛出这个异常？】
 * 志愿者接单/拒单时，传入的订单ID在数据库中不存在。
 * GlobalExceptionHandler 会捕获它并返回 HTTP 404。
 */
public class OrderNotFoundException extends RuntimeException {
    public OrderNotFoundException(String message) {
        super(message);
    }
}
