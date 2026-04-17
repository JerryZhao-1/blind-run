package com.example.demo.service.impl;

import com.example.demo.service.SmsService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

/**
 * 模拟短信服务 —— 开发阶段使用，验证码直接打印到控制台
 *
 * 【@Slf4j 是什么？】
 * Lombok 注解，自动生成一个 log 对象（日志记录器）。
 * 有了它，可以直接使用 log.info()、log.error() 等方法记录日志。
 * 日志比 System.out.println 更专业：可以设置级别、写入文件等。
 *
 * 【@Service 是什么？】
 * 告诉 Spring："这是一个业务逻辑类，请帮我管理它的对象"。
 * 效果和 @Component 一样，但语义更清晰 —— 让人一看就知道这是业务层。
 * Spring 会自动创建这个类的实例（Bean），其他地方可以通过注入来使用。
 */
@Slf4j
@Service
public class MockSmsServiceImpl implements SmsService {

    /**
     * 模拟发送短信 —— 将验证码打印到控制台和日志
     *
     * 开发时看控制台就能获取验证码，不需要真的发短信。
     * 等上线时，再写一个真正的实现类替换掉这个就行。
     */
    @Override
    public void sendVerificationCode(String phone, String code) {
        // 打印到控制台（方便直接看到）
        System.out.println("========================================");
        System.out.println("【模拟短信】手机号: " + phone + " 验证码: " + code);
        System.out.println("========================================");

        // 同时记录到日志（方便排查问题）
        log.info("【模拟短信】手机号: {} 验证码: {}", phone, code);
    }
}
