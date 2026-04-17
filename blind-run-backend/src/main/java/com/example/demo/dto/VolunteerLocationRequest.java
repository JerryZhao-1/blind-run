package com.example.demo.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

/**
 * 志愿者位置上报请求 DTO
 *
 * 【什么是 DTO？】
 * DTO（Data Transfer Object）是前后端之间传递数据的载体。
 * 前端发送 JSON，Spring 自动转换成这个 Java 对象。
 *
 * 【字段说明】
 * latitude  纬度（-90 到 90）
 * longitude 经度（-180 到 180）
 * isOnline  是否在线可接单（默认 true）
 */
@Data
public class VolunteerLocationRequest {

    /** 纬度，不能为空，范围 -90 到 90 */
    @NotNull(message = "纬度不能为空")
    @Min(value = -90, message = "纬度不能小于 -90")
    @Max(value = 90, message = "纬度不能大于 90")
    private Double latitude;

    /** 经度，不能为空，范围 -180 到 180 */
    @NotNull(message = "经度不能为空")
    @Min(value = -180, message = "经度不能小于 -180")
    @Max(value = 180, message = "经度不能大于 180")
    private Double longitude;

    /** 是否在线可接单，默认 true */
    private Boolean isOnline = true;
}
