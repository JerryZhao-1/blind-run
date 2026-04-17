package com.example.demo.websocket;

import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.handler.TextWebSocketHandler;
import org.springframework.web.socket.WebSocketSession;

/**
 * 志愿者 WebSocket 处理器 —— 处理志愿者的 WebSocket 连接事件
 *
 * 【什么是 WebSocket？】
 * HTTP 请求是"一问一答"模式（前端问，后端答）。
 * WebSocket 是"持久连接"模式，建立连接后双方可以随时发消息。
 * 适合实时推送场景（如：有新订单时立即通知志愿者）。
 *
 * 【为什么继承 TextWebSocketHandler？】
 * Spring 提供的 WebSocket 处理器基类，我们只需要重写需要的回调方法：
 * - afterConnectionEstablished  连接建立时
 * - afterConnectionClosed       连接关闭时
 * - handleTransportError        连接出错时
 *
 * 【工作流程】
 * 1. 志愿者前端建立 WebSocket 连接（携带 JWT token 认证）
 * 2. 连接成功 → 从 session 中取出 userId → 注册到 VolunteerSessionRegistry
 * 3. 有新订单时，MatchingService 通过 VolunteerSessionRegistry 推送消息
 * 4. 志愿者断开连接 → 从注册表中移除
 */
@Slf4j
@Component
public class VolunteerWebSocketHandler extends TextWebSocketHandler {

    private final VolunteerSessionRegistry sessionRegistry;

    public VolunteerWebSocketHandler(VolunteerSessionRegistry sessionRegistry) {
        this.sessionRegistry = sessionRegistry;
    }

    /**
     * 连接建立成功时的回调
     * 从 session attributes 中取出 userId（由 JwtHandshakeInterceptor 设置）
     * 注册到 VolunteerSessionRegistry
     */
    @Override
    public void afterConnectionEstablished(WebSocketSession session) throws Exception {
        Long userId = getUserIdFromSession(session);
        if (userId != null) {
            sessionRegistry.register(userId, session);
        } else {
            log.warn("WebSocket 连接缺少用户ID信息，关闭连接");
            session.close(CloseStatus.POLICY_VIOLATION);
        }
    }

    /**
     * 连接关闭时的回调
     * 从注册表中移除该志愿者
     */
    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) throws Exception {
        Long userId = getUserIdFromSession(session);
        if (userId != null) {
            sessionRegistry.unregister(userId);
        }
    }

    /**
     * 传输错误时的回调
     * 记录日志并从注册表中移除
     */
    @Override
    public void handleTransportError(WebSocketSession session, Throwable exception) throws Exception {
        Long userId = getUserIdFromSession(session);
        log.error("志愿者 {} WebSocket 传输错误: {}", userId, exception.getMessage());
        if (session.isOpen()) {
            session.close(CloseStatus.SERVER_ERROR);
        }
    }

    /**
     * 从 WebSocket session 的 attributes 中提取用户ID
     * 这个值是在 HandshakeInterceptor 中设置的
     */
    private Long getUserIdFromSession(WebSocketSession session) {
        Object userId = session.getAttributes().get("userId");
        return userId instanceof Long ? (Long) userId : null;
    }
}
