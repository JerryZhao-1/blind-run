package com.example.demo.entity;

/**
 * 取消方枚举 —— 记录是谁取消了订单
 *
 * BLIND     盲人用户取消
 * VOLUNTEER 志愿者取消（IN_PROGRESS 阶段取消视为爽约）
 */
public enum CancelledBy {
    BLIND,
    VOLUNTEER
}
