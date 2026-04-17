package com.example.demo.dto;

import lombok.Data;

import java.util.List;

/**
 * 志愿者资料更新请求 DTO
 */
@Data
public class VolunteerProfileUpdateRequest {
    private String name;
    private List<VolunteerAvailableTimeSlot> availableTimeSlots;
}
