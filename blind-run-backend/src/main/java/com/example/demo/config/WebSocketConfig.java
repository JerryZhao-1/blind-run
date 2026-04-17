package com.example.demo.config;

import com.example.demo.filter.JwtHandshakeInterceptor;
import com.example.demo.websocket.VolunteerWebSocketHandler;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.socket.config.annotation.EnableWebSocket;
import org.springframework.web.socket.config.annotation.WebSocketConfigurer;
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry;

/**
 * WebSocket 配置类 —— 注册 WebSocket 端点和拦截器
 *
 * 【什么是端点？】
 * 端点就是 WebSocket 连接的地址，类似 HTTP 接口的 URL。
 * 志愿者前端通过连接这个地址来接收订单推送。
 *
 * 【配置内容】
 * 1. 端点路径：/ws/volunteer（可在 application.properties 中配置）
 * 2. 握手拦截器：JwtHandshakeInterceptor（验证 JWT token）
 * 3. 允许跨域（前端可能在不同的域名下）
 *
 * 【连接方式】
 * ws://localhost:8081/ws/volunteer?token=<jwt_token>
 */
@Configuration
@EnableWebSocket
public class WebSocketConfig implements WebSocketConfigurer {

    @Value("${app.websocket.endpoint:/ws/volunteer}")
    private String endpoint;

    private final VolunteerWebSocketHandler volunteerWebSocketHandler;
    private final JwtHandshakeInterceptor jwtHandshakeInterceptor;

    public WebSocketConfig(VolunteerWebSocketHandler volunteerWebSocketHandler,
                           JwtHandshakeInterceptor jwtHandshakeInterceptor) {
        this.volunteerWebSocketHandler = volunteerWebSocketHandler;
        this.jwtHandshakeInterceptor = jwtHandshakeInterceptor;
    }

    @Override
    public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
        registry.addHandler(volunteerWebSocketHandler, endpoint)
                .addInterceptors(jwtHandshakeInterceptor)
                .setAllowedOriginPatterns("*");
    }
}
