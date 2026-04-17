package com.example.demo.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

/**
 * 发送验证码请求 —— 用户输入手机号后，前端发这个请求给后端
 *
 * 【什么是 DTO？】
 * DTO = Data Transfer Object（数据传输对象）。
 * 它是前端和后端之间传递数据的 "快递箱"。
 * 前端发来的 JSON 数据会自动填入这个类的字段中。
 *
 * 例如前端发送：{ "phone": "13800138000" }
 * Spring 会自动把 "13800138000" 填入 phone 字段。
 */
@Data
public class SendCodeRequest {

    /**
     * 手机号
     *
     * @NotBlank —— 参数校验注解，确保手机号不能为空
     *   message 属性：校验失败时的错误提示信息
     *   当 phone 为 null、空字符串、或只有空格时，校验会失败
     */
    @NotBlank(message = "手机号不能为空")
    private String phone;
}
