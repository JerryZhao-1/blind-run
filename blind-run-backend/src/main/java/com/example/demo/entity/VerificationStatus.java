package com.example.demo.entity;

/**
 * 志愿者认证状态枚举
 */
public enum VerificationStatus {
    /** 未申请 */
    NONE,
    /** 审核中 */
    PENDING,
    /** 已通过 */
    APPROVED,
    /** 已拒绝 */
    REJECTED
}
