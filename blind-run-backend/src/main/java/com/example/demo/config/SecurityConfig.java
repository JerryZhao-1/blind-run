package com.example.demo.config;

import com.example.demo.filter.JwtFilter;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;

import java.util.List;

/**
 * Spring Security 安全配置 —— 定义 "哪些接口需要登录才能访问"
 *
 * 【安全规则说明】
 * - /api/auth/**    → 所有人都可以访问（不需要登录），包括发送验证码和验证登录
 * - 其他所有接口    → 必须携带有效的 JWT token 才能访问
 *
 * 【为什么不需要 PasswordEncoder 了？】
 * 原来的配置有 BCryptPasswordEncoder（密码加密器），
 * 但现在用短信验证码登录，不再有密码字段，所以删掉了。
 *
 * 【什么是 CSRF？为什么禁用？】
 * CSRF（跨站请求伪造）是一种攻击方式。
 * 因为我们用 JWT token 认证（不是 Cookie），天然免疫 CSRF 攻击，所以可以禁用。
 *
 * 【SessionCreationPolicy.STATELESS 是什么意思？】
 * "无状态" —— 服务器不保存用户的登录状态（不使用 Session）。
 * 每次请求都通过 JWT token 来验证身份。
 * 这适合前后端分离的架构和 RESTful API。
 */
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Autowired
    private JwtFilter jwtFilter;

    /**
     * 安全过滤器链 —— 配置安全规则
     */
    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                // 启用 CORS（允许前端跨域访问）
                .cors(cors -> cors.configurationSource(request -> {
                    CorsConfiguration config = new CorsConfiguration();
                    config.setAllowedOriginPatterns(List.of("*"));
                    config.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "OPTIONS"));
                    config.setAllowedHeaders(List.of("*"));
                    config.setAllowCredentials(true);
                    return config;
                }))
                // 禁用 CSRF（因为使用 JWT，不需要）
                .csrf(csrf -> csrf.disable())
                // 设置为无状态会话（不使用 Session）
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                // 配置URL权限规则
                .authorizeHttpRequests(auth -> auth
                        // 认证相关接口（发送验证码、验证登录）允许匿名访问
                        .requestMatchers("/api/auth/**").permitAll()
                        // WebSocket 握手端点允许匿名访问（认证在 HandshakeInterceptor 中处理）
                        .requestMatchers("/ws/volunteer/**").permitAll()
                        // 其他所有接口需要认证（必须携带有效 JWT token）
                        .anyRequest().authenticated()
                )
                // 未认证请求返回 401（而非默认的 403）
                .exceptionHandling(ex -> ex
                        .authenticationEntryPoint((request, response, authException) ->
                                response.sendError(401, "未认证"))
                )
                // 在 Spring Security 的过滤器链中插入我们的 JWT 过滤器
                // 在 UsernamePasswordAuthenticationFilter 之前执行
                .addFilterBefore(jwtFilter, UsernamePasswordAuthenticationFilter.class)
                // 未认证请求返回 401（默认返回 403，不适合 REST API）
                .exceptionHandling(ex -> ex
                        .authenticationEntryPoint((request, response, authException) ->
                                response.sendError(401, "未认证")));

        return http.build();
    }
}
