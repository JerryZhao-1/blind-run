package com.example.demo.dto;

import com.example.demo.entity.UserRole;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

/**
 * 设置角色请求 DTO
 */
@Data
public class SetRoleRequest {

    @NotNull(message = "角色不能为空")
    private UserRole role;
}
