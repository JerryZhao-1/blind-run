package com.example.demo.dto;

import lombok.Data;

import java.time.LocalTime;

/**
 * 志愿者可用时间段 DTO
 */
@Data
public class VolunteerAvailableTimeSlot {
    private String dayOfWeek;
    private LocalTime startTime;
    private LocalTime endTime;
}
