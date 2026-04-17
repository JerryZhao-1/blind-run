package com.example.demo.controller;

import com.example.demo.dto.LoginResponse;
import com.example.demo.dto.SendCodeRequest;
import com.example.demo.dto.VerifyCodeRequest;
import com.example.demo.entity.User;
import com.example.demo.service.AuthService;
import com.example.demo.util.PhoneMaskUtils;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * 认证控制器 —— 处理用户登录相关的 HTTP 请求
 *
 * POST /api/auth/send-code  → 发送验证码
 * POST /api/auth/verify-code → 验证码登录
 * GET  /api/auth/me          → 获取当前用户信息
 */
@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/send-code")
    public ResponseEntity<?> sendCode(@Valid @RequestBody SendCodeRequest request) {
        authService.sendVerificationCode(request.getPhone());
        return ResponseEntity.ok().body(Map.of("success", true));
    }

    @PostMapping("/verify-code")
    public ResponseEntity<LoginResponse> verifyCode(@Valid @RequestBody VerifyCodeRequest request) {
        LoginResponse response = authService.verifyCodeAndLogin(request.getPhone(), request.getCode());
        return ResponseEntity.ok(response);
    }

    @GetMapping("/me")
    public ResponseEntity<?> getCurrentUser() {
        var auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !(auth.getPrincipal() instanceof Long)) {
            return ResponseEntity.status(401).body(Map.of("error", "未登录"));
        }
        Long userId = (Long) auth.getPrincipal();
        User user = authService.getCurrentUser(userId);

        return ResponseEntity.ok(Map.of(
                "userId", user.getId(),
                "phone", PhoneMaskUtils.mask(user.getPhone()),
                "role", user.getRole() != null ? user.getRole().name() : "UNSET",
                "createdAt", user.getCreatedAt() != null ? user.getCreatedAt().toString() : ""
        ));
    }
}
