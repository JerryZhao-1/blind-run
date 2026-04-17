package com.example.demo.entity;

import jakarta.persistence.*;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 用户实体类 —— 对应数据库中的 users 表
 *
 * 【什么是 Entity？】
 * Entity 是 "实体" 的意思，它和数据库表是一一对应的。
 * 这个 User 类对应数据库中的 users 表，类的每个字段对应表中的一列。
 * Spring Data JPA 框架会自动根据这个类来创建/更新数据库表。
 *
 * 【为什么不需要 password 字段了？】
 * 因为我们改用手机号+短信验证码登录，不再需要密码。
 */
@Data                           // Lombok 注解：自动生成 getter、setter、toString 等方法，省去手写
@Entity                         // JPA 注解：标记这个类是一个数据库实体（对应一张表）
@Table(name = "users")          // 指定数据库中的表名为 "users"
public class User {

    /**
     * 用户ID —— 主键，由数据库自动递增
     *
     * @Id             标记这是主键
     * @GeneratedValue  主键的生成策略，IDENTITY 表示使用数据库的自增功能
     */
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * 用户昵称
     * 新用户自动注册时，默认名字为 "用户" + 手机号后4位
     */
    private String name;

    /**
     * 手机号 —— 用户唯一的身份标识
     *
     * @Column(unique = true)  手机号必须唯一，不能重复注册
     * @Column(nullable = false) 手机号不能为空
     *
     * 【为什么用手机号替代邮箱？】
     * 因为目标用户是盲人，手机号比邮箱更容易通过语音播报输入，
     * 而且短信验证码登录比输入密码更方便。
     */
    @Column(unique = true, nullable = false)
    private String phone;

    /**
     * 用户角色 —— UNSET（未设定）/ BLIND（盲人）/ VOLUNTEER（志愿者）
     * 注册时默认 UNSET，用户选择身份后设定，一旦设定不可修改
     */
    @Enumerated(EnumType.STRING)
    @Column(length = 16)
    private UserRole role = UserRole.UNSET;

    /** 软删除时间 —— 不为 null 表示已注销 */
    @Column(name = "deleted_at")
    private LocalDateTime deletedAt;

    /** 创建时间 */
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
}
