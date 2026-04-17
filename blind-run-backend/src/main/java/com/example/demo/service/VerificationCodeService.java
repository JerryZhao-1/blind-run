package com.example.demo.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.util.concurrent.ThreadLocalRandom;
import java.util.concurrent.TimeUnit;

/**
 * 验证码管理服务 —— 基于 Redis 存储验证码
 *
 * Key: sms:code:{phone}
 * Value: JSON { "code": "123456", "attempts": 0 }
 * TTL: 5 分钟
 */
@Slf4j
@Service
public class VerificationCodeService {

    private final StringRedisTemplate redisTemplate;
    private final ObjectMapper objectMapper;

    @Value("${sms.code.length:6}")
    private int codeLength;

    @Value("${sms.code.ttl-minutes:5}")
    private int ttlMinutes;

    @Value("${sms.code.max-attempts:5}")
    private int maxAttempts;

    public VerificationCodeService(StringRedisTemplate redisTemplate, ObjectMapper objectMapper) {
        this.redisTemplate = redisTemplate;
        this.objectMapper = objectMapper;
    }

    /** 验证码信息 */
    private record CodeEntry(String code, int attempts) {}

    /** 生成验证码并存储到 Redis */
    public String generateAndStoreCode(String phone) {
        int min = (int) Math.pow(10, codeLength - 1);
        int max = (int) Math.pow(10, codeLength);
        String code = String.valueOf(ThreadLocalRandom.current().nextInt(min, max));

        try {
            String json = objectMapper.writeValueAsString(new CodeEntry(code, 0));
            redisTemplate.opsForValue().set("sms:code:" + phone, json, ttlMinutes, TimeUnit.MINUTES);
        } catch (JsonProcessingException e) {
            throw new RuntimeException("验证码存储失败", e);
        }

        log.info("为手机号 {} 生成验证码，有效期 {} 分钟", phone, ttlMinutes);
        return code;
    }

    /** 校验验证码 */
    public boolean verifyCode(String phone, String inputCode) {
        String key = "sms:code:" + phone;
        String json = redisTemplate.opsForValue().get(key);

        if (json == null) {
            log.warn("手机号 {} 没有验证码记录或已过期", phone);
            return false;
        }

        try {
            CodeEntry entry = objectMapper.readValue(json, CodeEntry.class);

            // 检查尝试次数
            int newAttempts = entry.attempts() + 1;
            if (newAttempts > maxAttempts) {
                redisTemplate.delete(key);
                log.warn("手机号 {} 验证码尝试次数超限", phone);
                return false;
            }

            // 比对验证码
            if (entry.code().equals(inputCode)) {
                redisTemplate.delete(key);
                log.info("手机号 {} 验证码验证成功", phone);
                return true;
            }

            // 更新尝试次数
            String updatedJson = objectMapper.writeValueAsString(new CodeEntry(entry.code(), newAttempts));
            Long ttl = redisTemplate.getExpire(key, TimeUnit.SECONDS);
            if (ttl != null && ttl > 0) {
                redisTemplate.opsForValue().set(key, updatedJson, ttl, TimeUnit.SECONDS);
            }

            log.warn("手机号 {} 验证码不匹配，已尝试 {}/{} 次", phone, newAttempts, maxAttempts);
            return false;
        } catch (JsonProcessingException e) {
            log.error("解析验证码数据失败", e);
            return false;
        }
    }
}
