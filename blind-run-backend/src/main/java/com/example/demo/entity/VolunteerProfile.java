package com.example.demo.entity;

import jakarta.persistence.*;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 志愿者资料实体 —— 对应数据库中的 volunteer_profile 表
 */
@Data
@Entity
@Table(name = "volunteer_profile")
public class VolunteerProfile {

    @Id
    private Long userId;

    @OneToOne(fetch = FetchType.LAZY)
    @MapsId
    @JoinColumn(name = "user_id")
    private User user;

    private String name;

    /** 是否已认证 */
    @Column(nullable = false)
    private Boolean verified = false;

    /** 认证状态 */
    @Enumerated(EnumType.STRING)
    @Column(name = "verification_status", length = 16, nullable = false)
    private VerificationStatus verificationStatus = VerificationStatus.NONE;

    /** 认证证件文件路径 */
    @Column(name = "verification_doc_url", length = 500)
    private String verificationDocUrl;

    @Column(name = "updated_at", nullable = false)
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
