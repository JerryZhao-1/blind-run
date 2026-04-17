package com.example.demo.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

/**
 * 登录成功响应
 */
@Data
@AllArgsConstructor
public class LoginResponse {
    /** JWT 令牌 */
    private String token;
    /** 用户ID */
    private Long userId;
    /** 用户角色 */
    private String role;
}
