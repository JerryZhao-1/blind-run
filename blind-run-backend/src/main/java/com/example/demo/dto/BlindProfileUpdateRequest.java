package com.example.demo.dto;

import lombok.Data;

/**
 * 盲人资料更新请求 DTO
 */
@Data
public class BlindProfileUpdateRequest {
    private String name;
    private String emergencyContactName;
    private String emergencyContactPhone;
    private String emergencyContactRelation;
    private String runningPace;
    private String specialNeeds;
}
