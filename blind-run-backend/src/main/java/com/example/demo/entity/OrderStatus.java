package com.example.demo.entity;

/**
 * 订单状态枚举 —— 定义订单在整个生命周期中的状态
 *
 * 【状态流转】
 * PENDING_MATCH  → PENDING_ACCEPT  （系统匹配成功）
 * PENDING_MATCH  → CANCELLED       （盲人取消）
 * PENDING_ACCEPT → IN_PROGRESS     （志愿者接单）
 * PENDING_ACCEPT → CANCELLED       （盲人取消 或 志愿者拒单）
 * IN_PROGRESS    → COMPLETED       （志愿者点击结束 或 系统超时自动完成）
 * IN_PROGRESS    → CANCELLED       （志愿者取消，记录为爽约）
 */
public enum OrderStatus {
    PENDING_MATCH,      // 待匹配：订单刚创建，等待系统匹配志愿者
    PENDING_ACCEPT,     // 待接受：已推送给志愿者，等待志愿者接受
    IN_PROGRESS,        // 进行中：志愿者已接单，服务进行中
    COMPLETED,          // 已完成：服务已完成
    CANCELLED           // 已取消
}
