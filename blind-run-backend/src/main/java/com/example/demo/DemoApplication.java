package com.example.demo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.annotation.EnableScheduling;

/**
 * Spring Boot 应用启动类 —— 程序的入口
 *
 * 【各注解的作用】
 * @SpringBootApplication —— 告诉 Spring "这是启动类"，包含三个功能：
 *   @Configuration      标记这是一个配置类
 *   @EnableAutoConfiguration 启用自动配置（Spring 自动配置数据库、Web 等）
 *   @ComponentScan       自动扫描当前包及子包下的所有组件
 *
 * @ComponentScan(basePackages = "com.example.demo")
 *   指定 Spring 要扫描的包路径，确保所有 @Controller、@Service 等注解都能被发现
 *
 * @EnableScheduling
 *   启用定时任务功能。VerificationCodeService 中的 @Scheduled 注解需要这个才能生效。
 *   用于定时清理过期的短信验证码。
 */
@SpringBootApplication
@ComponentScan(basePackages = "com.example.demo")
@EnableScheduling
@EnableAsync
public class DemoApplication {

    public static void main(String[] args) {
        SpringApplication.run(DemoApplication.class, args);
    }
}
