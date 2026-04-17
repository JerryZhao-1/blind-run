package com.example.demo.entity;

import jakarta.persistence.*;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 志愿者位置实体类 —— 对应数据库中的 volunteer_location 表
 *
 * 【这个表存什么？】
 * 志愿者上报的实时 GPS 位置，用于距离匹配计算。
 *
 * 【为什么需要这个表？】
 * Redis 缓存志愿者的位置以加速匹配查询，但 Redis 重启后数据会丢失。
 * 这个表作为持久化备份，当 Redis 没数据时可以从数据库查询。
 *
 * 【更新频率】
 * 志愿者前端每 10 秒调用一次位置上报接口，更新此表和 Redis。
 * Redis 的 TTL 设为 30 秒，超过 30 秒未更新视为离线。
 */
@Data
@Entity
@Table(name = "volunteer_location")
public class VolunteerLocation {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * 关联的志愿者用户 —— 多对一关系
     * 一个志愿者只有一条位置记录（最新位置）
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "volunteer_id", nullable = false)
    private User volunteer;

    /** 纬度 */
    @Column(nullable = false)
    private Double latitude;

    /** 经度 */
    @Column(nullable = false)
    private Double longitude;

    /**
     * 是否在线（可接单）
     * true = 可以接单，false = 不接单
     */
    @Column(nullable = false)
    private Boolean isOnline = false;

    /** 最后一次上报时间 */
    @Column(nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
