package com.example.demo.util;

import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.util.Date;

/**
 * JWT 工具类 —— 负责生成和验证 JWT 令牌
 *
 * 【什么是 JWT？】
 * JWT（JSON Web Token）是一种安全的身份认证方式。
 * 可以把它想象成一张 "加密的电子身份证"，里面写着 "这个人是手机号 138xxxx 的用户"。
 *
 * 工作流程：
 * 1. 用户登录成功 → JwtUtil 生成 token（相当于签发身份证）
 * 2. 前端保存 token，每次请求都带上
 * 3. 后端收到请求 → JwtUtil 验证 token（相当于查验身份证）
 *
 * 【@Component 是什么？】
 * 告诉 Spring："请帮我管理这个类的对象"。
 * 这样其他地方就可以通过构造函数注入来使用它，不需要手动 new。
 */
@Component
public class JwtUtil {

    /**
     * JWT 签名密钥 —— 用于加密和解密 token
     *
     * @Value 注解：从 application.properties 配置文件中读取 jwt.secret 的值
     * 冒号后面是默认值：如果配置文件中没有配置，就用这个默认值
     */
    @Value("${jwt.secret:mySecretKeyForJwtTokenGenerationThatShouldBeAtLeast256BitsLong}")
    private String secret;

    /**
     * Token 过期时间（毫秒）
     * 默认 86400000 毫秒 = 24 小时
     */
    @Value("${jwt.expiration:86400000}")
    private long expiration;

    /**
     * 根据密钥字符串生成加密密钥对象
     */
    private SecretKey getSigningKey() {
        return Keys.hmacShaKeyFor(secret.getBytes());
    }

    /**
     * 生成 JWT Token
     *
     * @param userId 用户ID（作为 token 的主体标识）
     * @return 生成的 JWT 字符串
     *
     * 生成的 token 结构：
     *   header.payload.signature
     *   header  = { 算法信息 }
     *   payload = { subject: "用户ID", issuedAt: 签发时间, expiration: 过期时间 }
     *   signature = 用密钥对前两部分进行签名，防止篡改
     */
    public String generateToken(Long userId) {
        return Jwts.builder()
                .subject(String.valueOf(userId))                   // token 主体：存入用户ID
                .issuedAt(new Date())                              // 签发时间：当前时间
                .expiration(new Date(System.currentTimeMillis() + expiration))  // 过期时间
                .signWith(getSigningKey())                         // 用密钥签名
                .compact();                                        // 拼装成字符串
    }

    /**
     * 从 token 中提取用户ID
     *
     * @param token JWT 字符串
     * @return 用户ID
     */
    public Long getUserIdFromToken(String token) {
        String subject = Jwts.parser()
                .verifyWith(getSigningKey())                       // 用密钥验证签名
                .build()
                .parseSignedClaims(token)                         // 解析 token
                .getPayload()
                .getSubject();                                    // 取出主体（用户ID字符串）
        return Long.parseLong(subject);                           // 转为 Long 类型
    }

    /**
     * 验证 token 是否有效
     *
     * @param token JWT 字符串
     * @return true = 有效，false = 无效（过期、被篡改、格式错误等）
     */
    public boolean validateToken(String token) {
        try {
            Jwts.parser()
                    .verifyWith(getSigningKey())
                    .build()
                    .parseSignedClaims(token);
            return true;
        } catch (JwtException | IllegalArgumentException e) {
            // 如果解析失败（过期、签名不匹配等），返回 false
            return false;
        }
    }
}
