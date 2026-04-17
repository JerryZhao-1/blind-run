package com.example.demo.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

/**
 * 评价响应 DTO
 */
@Data
@AllArgsConstructor
public class ReviewResponse {
    private Long orderId;
    private Integer rating;
    private String comment;
    private String createdAt;
}
