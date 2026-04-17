package com.example.demo.exception;

import org.springframework.dao.OptimisticLockingFailureException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.util.Map;
import java.util.stream.Collectors;

/**
 * 全局异常处理器 —— 统一管理所有接口的错误返回格式
 *
 * 【两种错误格式】
 * - 旧接口（登录/用户管理）：{ "error": "错误信息" }
 * - 新接口（订单/志愿者）：{ "success": false, "code": 409, "message": "错误信息" }
 */
@RestControllerAdvice
public class GlobalExceptionHandler {

    /** 认证异常 → 400 */
    @ExceptionHandler(AuthException.class)
    public ResponseEntity<Map<String, String>> handleAuthException(AuthException e) {
        return ResponseEntity
                .status(HttpStatus.BAD_REQUEST)
                .body(Map.of("error", e.getMessage()));
    }

    /** 资源未找到 → 404（旧格式） */
    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<Map<String, String>> handleResourceNotFound(ResourceNotFoundException e) {
        return ResponseEntity
                .status(HttpStatus.NOT_FOUND)
                .body(Map.of("error", e.getMessage()));
    }

    /** 订单不存在 → 404（新格式） */
    @ExceptionHandler(OrderNotFoundException.class)
    public ResponseEntity<Map<String, Object>> handleOrderNotFound(OrderNotFoundException e) {
        return ResponseEntity
                .status(HttpStatus.NOT_FOUND)
                .body(Map.of("success", false, "code", 404, "message", e.getMessage()));
    }

    /** 重复订单 → 409 */
    @ExceptionHandler(DuplicateOrderException.class)
    public ResponseEntity<Map<String, Object>> handleDuplicateOrder(DuplicateOrderException e) {
        return ResponseEntity
                .status(HttpStatus.CONFLICT)
                .body(Map.of("success", false, "code", 409, "message", e.getMessage()));
    }

    /** 订单状态流转异常 → 409 */
    @ExceptionHandler(OrderStatusException.class)
    public ResponseEntity<Map<String, Object>> handleOrderStatus(OrderStatusException e) {
        return ResponseEntity
                .status(HttpStatus.CONFLICT)
                .body(Map.of("success", false, "code", 409, "message", e.getMessage()));
    }

    /** 角色已设定异常 → 409 */
    @ExceptionHandler(RoleAlreadySetException.class)
    public ResponseEntity<Map<String, Object>> handleRoleAlreadySet(RoleAlreadySetException e) {
        return ResponseEntity
                .status(HttpStatus.CONFLICT)
                .body(Map.of("success", false, "code", 409, "message", e.getMessage()));
    }

    /** 订单权限异常 → 403 */
    @ExceptionHandler(OrderPermissionException.class)
    public ResponseEntity<Map<String, Object>> handleOrderPermission(OrderPermissionException e) {
        return ResponseEntity
                .status(HttpStatus.FORBIDDEN)
                .body(Map.of("success", false, "code", 403, "message", e.getMessage()));
    }

    /** 权限不足异常 → 403 */
    @ExceptionHandler(PermissionDeniedException.class)
    public ResponseEntity<Map<String, Object>> handlePermissionDenied(PermissionDeniedException e) {
        return ResponseEntity
                .status(HttpStatus.FORBIDDEN)
                .body(Map.of("success", false, "code", 403, "message", e.getMessage()));
    }

    /** 参数校验异常 → 400 */
    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<Map<String, Object>> handleIllegalArgument(IllegalArgumentException e) {
        return ResponseEntity
                .status(HttpStatus.BAD_REQUEST)
                .body(Map.of("success", false, "code", 400, "message", e.getMessage()));
    }

    /** @Valid 校验失败 → 400 */
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, Object>> handleValidationException(MethodArgumentNotValidException e) {
        String errorMessage = e.getBindingResult().getFieldErrors().stream()
                .map(error -> error.getField() + ": " + error.getDefaultMessage())
                .collect(Collectors.joining(", "));

        return ResponseEntity
                .status(HttpStatus.BAD_REQUEST)
                .body(Map.of("success", false, "code", 400, "message", errorMessage));
    }

    /** 乐观锁冲突 → 409 */
    @ExceptionHandler(OptimisticLockingFailureException.class)
    public ResponseEntity<Map<String, Object>> handleOptimisticLock(OptimisticLockingFailureException e) {
        return ResponseEntity
                .status(HttpStatus.CONFLICT)
                .body(Map.of("success", false, "code", 409, "message", "订单已被其他志愿者接单"));
    }

    /** 兜底：其他未捕获异常 → 500 */
    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, Object>> handleGenericException(Exception e) {
        return ResponseEntity
                .status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("success", false, "code", 500, "message", "服务器内部错误，请稍后重试"));
    }
}
