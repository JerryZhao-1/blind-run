package com.example.demo.entity;

import jakarta.persistence.*;
import lombok.Data;

import java.time.LocalTime;

/**
 * 志愿者可用时间实体 —— 对应数据库中的 volunteer_available_time 表
 */
@Data
@Entity
@Table(name = "volunteer_available_time")
public class VolunteerAvailableTime {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "volunteer_id", nullable = false)
    private Long volunteerId;

    @Column(name = "day_of_week", nullable = false, length = 10)
    private String dayOfWeek;

    @Column(name = "start_time", nullable = false)
    private LocalTime startTime;

    @Column(name = "end_time", nullable = false)
    private LocalTime endTime;
}
