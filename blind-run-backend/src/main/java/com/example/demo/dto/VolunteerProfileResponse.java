package com.example.demo.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

import java.util.List;

/**
 * 志愿者资料响应 DTO
 */
@Data
@AllArgsConstructor
public class VolunteerProfileResponse {
    private String name;
    private String verificationStatus;
    private List<VolunteerAvailableTimeSlot> availableTimeSlots;
}
