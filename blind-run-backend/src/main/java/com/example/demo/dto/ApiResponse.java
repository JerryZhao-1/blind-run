package com.example.demo.dto;

import lombok.Data;

/**
 * 统一响应格式
 */
@Data
public class ApiResponse<T> {
    private boolean success;
    private int code;
    private String message;
    private T data;

    public static <T> ApiResponse<T> ok(T data) {
        ApiResponse<T> r = new ApiResponse<>();
        r.success = true;
        r.code = 200;
        r.message = "success";
        r.data = data;
        return r;
    }

    public static <T> ApiResponse<T> created(T data) {
        ApiResponse<T> r = new ApiResponse<>();
        r.success = true;
        r.code = 201;
        r.message = "created";
        r.data = data;
        return r;
    }

    public static ApiResponse<Void> error(int code, String message) {
        ApiResponse<Void> r = new ApiResponse<>();
        r.success = false;
        r.code = code;
        r.message = message;
        return r;
    }
}
