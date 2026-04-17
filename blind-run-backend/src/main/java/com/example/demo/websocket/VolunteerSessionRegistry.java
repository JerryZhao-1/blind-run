package com.example.demo.websocket;

import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;

import java.io.IOException;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;

/**
 * 志愿者 WebSocket 会话注册表 —— 管理所有在线志愿者的 WebSocket 连接
 *
 * 【什么是会话（Session）？】
 * 当志愿者通过 WebSocket 连接到服务器时，服务器会为这个连接创建一个 "会话" 对象。
 * 我们需要记住"哪个志愿者对应哪个会话"，这样才能在有新订单时精确推送给指定志愿者。
 *
 * 【为什么用 ConcurrentHashMap？】
 * 多个志愿者可能同时连接或断开，ConcurrentHashMap 是线程安全的，
 * 不会出现并发问题（比如一个志愿者正在连接，另一个正在断开）。
 *
 * 【key 和 value】
 * key:   志愿者用户ID（Long）
 * value: WebSocket 会话对象（WebSocketSession）
 */
@Slf4j
@Component
public class VolunteerSessionRegistry {

    /** 志愿者ID → WebSocket 会话 的映射表 */
    private final ConcurrentHashMap<Long, WebSocketSession> sessions = new ConcurrentHashMap<>();

    /**
     * 注册一个志愿者的 WebSocket 连接
     * 如果该志愿者已有连接，先关闭旧连接再注册新的
     *
     * @param volunteerId 志愿者用户ID
     * @param session     WebSocket 会话
     */
    public void register(Long volunteerId, WebSocketSession session) {
        WebSocketSession oldSession = sessions.put(volunteerId, session);
        if (oldSession != null && oldSession.isOpen()) {
            try {
                oldSession.close();
            } catch (IOException e) {
                log.warn("关闭志愿者 {} 的旧 WebSocket 连接失败", volunteerId);
            }
        }
        log.info("志愿者 {} WebSocket 已连接，当前在线志愿者数: {}", volunteerId, sessions.size());
    }

    /**
     * 注销一个志愿者的 WebSocket 连接
     *
     * @param volunteerId 志愿者用户ID
     */
    public void unregister(Long volunteerId) {
        sessions.remove(volunteerId);
        log.info("志愿者 {} WebSocket 已断开，当前在线志愿者数: {}", volunteerId, sessions.size());
    }

    /**
     * 获取指定志愿者的 WebSocket 会话
     *
     * @param volunteerId 志愿者用户ID
     * @return WebSocket 会话（可能为空，表示该志愿者未连接）
     */
    public Optional<WebSocketSession> getSession(Long volunteerId) {
        return Optional.ofNullable(sessions.get(volunteerId));
    }

    /**
     * 向指定志愿者发送消息
     * 如果发送失败（连接已断开），自动从注册表中移除
     *
     * @param volunteerId 志愿者用户ID
     * @param message     要发送的消息（JSON 字符串）
     */
    public void sendToUser(Long volunteerId, String message) {
        Optional<WebSocketSession> sessionOpt = getSession(volunteerId);
        if (sessionOpt.isEmpty()) {
            log.warn("志愿者 {} 未连接 WebSocket，无法推送消息", volunteerId);
            return;
        }

        WebSocketSession session = sessionOpt.get();
        if (!session.isOpen()) {
            log.warn("志愿者 {} 的 WebSocket 已关闭，移除注册", volunteerId);
            unregister(volunteerId);
            return;
        }

        try {
            session.sendMessage(new TextMessage(message));
            log.debug("已向志愿者 {} 推送消息", volunteerId);
        } catch (IOException e) {
            log.warn("向志愿者 {} 推送消息失败，移除注册: {}", volunteerId, e.getMessage());
            unregister(volunteerId);
        }
    }
}
