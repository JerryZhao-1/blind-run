package com.example.demo.exception;

/**
 * 资源未找到异常 —— 当查询的用户不存在时抛出
 *
 * 例如：根据 ID 查询用户，但数据库中没有这个 ID 的用户，
 * 就抛出这个异常，由 GlobalExceptionHandler 统一转换为 404 响应。
 */
public class ResourceNotFoundException extends RuntimeException {

    public ResourceNotFoundException(String message) {
        super(message);
    }
}
