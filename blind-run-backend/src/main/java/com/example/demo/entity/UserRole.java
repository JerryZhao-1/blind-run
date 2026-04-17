package com.example.demo.entity;

/**
 * 用户角色枚举 —— 区分盲人和志愿者身份
 */
public enum UserRole {
    /** 未设定角色（新用户默认状态） */
    UNSET,
    /** 盲人用户：可以下单预约陪跑服务 */
    BLIND,
    /** 志愿者：可以接单提供陪跑服务 */
    VOLUNTEER
}
