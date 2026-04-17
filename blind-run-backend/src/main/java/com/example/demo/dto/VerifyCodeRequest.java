package com.example.demo.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

/**
 * 验证码登录请求 —— 用户输入手机号和收到的验证码，前端发这个请求给后端
 *
 * 例如前端发送：{ "phone": "13800138000", "code": "123456" }
 */
@Data
public class VerifyCodeRequest {

    /**
     * 手机号
     */
    @NotBlank(message = "手机号不能为空")
    private String phone;

    /**
     * 短信验证码（6位数字）
     */
    @NotBlank(message = "验证码不能为空")
    private String code;
}
