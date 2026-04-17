package com.example.demo.filter;

import com.example.demo.util.JwtUtil;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.server.ServerHttpRequest;
import org.springframework.http.server.ServerHttpResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.WebSocketHandler;
import org.springframework.web.socket.server.HandshakeInterceptor;

import java.util.Map;

/**
 * WebSocket 握手拦截器 —— 在 WebSocket 连接建立前验证 JWT token
 *
 * 【为什么需要这个？】
 * HTTP 接口的认证通过 JwtFilter（从 Authorization header 取 token）。
 * 但 WebSocket 连接无法设置 HTTP header，所以 token 通过 URL 参数传递：
 *   ws://localhost:8081/ws/volunteer?token=xxx
 *
 * 【工作流程】
 * 1. 志愿者前端发起 WebSocket 连接，URL 中带上 token 参数
 * 2. 这个拦截器在连接建立前执行
 * 3. 从 URL 中取出 token，用 JwtUtil 验证
 * 4. 验证通过 → 把 userId 存入 session attributes，允许连接
 * 5. 验证失败 → 拒绝连接
 */
@Slf4j
@Component
public class JwtHandshakeInterceptor implements HandshakeInterceptor {

    private final JwtUtil jwtUtil;

    public JwtHandshakeInterceptor(JwtUtil jwtUtil) {
        this.jwtUtil = jwtUtil;
    }

    /**
     * 握手前执行 —— 验证 JWT token
     *
     * @return true = 允许连接，false = 拒绝连接
     */
    @Override
    public boolean beforeHandshake(ServerHttpRequest request, ServerHttpResponse response,
                                    WebSocketHandler wsHandler, Map<String, Object> attributes) {
        // 从 URL query 参数中提取 token
        String query = request.getURI().getQuery();
        if (query == null || !query.contains("token=")) {
            log.warn("WebSocket 握手失败：缺少 token 参数");
            return false;
        }

        // 解析 token 参数值
        String token = null;
        for (String param : query.split("&")) {
            if (param.startsWith("token=")) {
                token = param.substring(6);
                break;
            }
        }

        if (token == null || token.isEmpty()) {
            log.warn("WebSocket 握手失败：token 为空");
            return false;
        }

        // 验证 token 有效性
        if (!jwtUtil.validateToken(token)) {
            log.warn("WebSocket 握手失败：token 无效或已过期");
            return false;
        }

        // 从 token 中提取用户ID，存入 session attributes
        try {
            Long userId = jwtUtil.getUserIdFromToken(token);
            attributes.put("userId", userId);
            log.info("WebSocket 握手成功：用户 {}", userId);
            return true;
        } catch (Exception e) {
            log.warn("WebSocket 握手失败：解析 token 出错 - {}", e.getMessage());
            return false;
        }
    }

    @Override
    public void afterHandshake(ServerHttpRequest request, ServerHttpResponse response,
                                WebSocketHandler wsHandler, Exception exception) {
        // 握手完成后的回调，不需要处理
    }
}
