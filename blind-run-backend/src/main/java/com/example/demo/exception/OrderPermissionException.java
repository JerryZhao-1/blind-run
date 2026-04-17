package com.example.demo.exception;

/**
 * 订单权限异常 —— 当用户无权操作某个订单时抛出
 *
 * 例如：盲人在 IN_PROGRESS 状态取消订单，或非订单相关用户尝试操作
 * GlobalExceptionHandler 会捕获它并返回 HTTP 403。
 */
public class OrderPermissionException extends RuntimeException {
    public OrderPermissionException(String message) {
        super(message);
    }
}
