package com.example.demo.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

/**
 * 盲人资料响应 DTO
 */
@Data
@AllArgsConstructor
public class BlindProfileResponse {
    private String name;
    private String emergencyContactName;
    private String emergencyContactPhone;
    private String emergencyContactRelation;
    private String runningPace;
    private String specialNeeds;
}
