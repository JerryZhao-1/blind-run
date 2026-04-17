package com.example.demo.service;

/**
 * 短信发送服务接口
 *
 * 【为什么要用接口而不是直接写实现类？】
 * 这是一种重要的设计模式叫 "面向接口编程"：
 * - 现在开发阶段：用 MockSmsServiceImpl（模拟短信，验证码打印到控制台）
 * - 以后上线时：只需写一个真实的实现类（比如接入阿里云短信），
 *               不需要修改其他任何代码！
 *
 * 就像插座和电器的关系：插座（接口）是固定的，电器（实现）可以随便换。
 */
public interface SmsService {

    /**
     * 发送短信验证码
     *
     * @param phone 目标手机号
     * @param code  验证码
     */
    void sendVerificationCode(String phone, String code);
}
