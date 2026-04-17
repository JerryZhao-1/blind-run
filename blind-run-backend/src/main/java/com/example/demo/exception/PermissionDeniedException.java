package com.example.demo.exception;

/**
 * 权限不足异常 —— 用于非订单场景的权限校验（如用户模块）
 */
public class PermissionDeniedException extends RuntimeException {
    public PermissionDeniedException(String message) {
        super(message);
    }
}
