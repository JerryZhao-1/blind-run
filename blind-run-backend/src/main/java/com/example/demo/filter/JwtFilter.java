package com.example.demo.filter;

import com.example.demo.util.JwtUtil;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.ArrayList;

/**
 * JWT 过滤器 —— 每个请求进来时，先到这里检查有没有有效的 JWT token
 *
 * 【什么是过滤器（Filter）？】
 * 过滤器就像公司门口的保安：每个请求（访客）进来之前都要先过这一关。
 * 这个保安的工作是：检查你有没有带有效的 "身份证"（JWT token）。
 *
 * 【工作流程】
 * 1. 从请求头中提取 Authorization 字段
 * 2. 格式应该是 "Bearer <token>"
 * 3. 验证 token 是否有效
 * 4. 如果有效，从 token 中取出手机号，告诉 Spring "这个请求是哪个用户的"
 * 5. 放行请求到下一个环节
 *
 * 【OncePerRequestFilter 是什么？】
 * 确保这个过滤器在每个请求中只执行一次。
 * 防止内部转发（forward）时重复执行。
 *
 * 【为什么用 @Component？】
 * 让 Spring 管理这个类的实例，这样 SecurityConfig 中可以注入它。
 */
@Component
public class JwtFilter extends OncePerRequestFilter {

    @Autowired
    private JwtUtil jwtUtil;

    /**
     * 过滤器的核心方法 —— 每个请求都会经过这里
     */
    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {

        // 1. 从请求头获取 Authorization 字段
        String header = request.getHeader("Authorization");

        // 2. 检查是否存在且以 "Bearer " 开头
        if (header != null && header.startsWith("Bearer ")) {
            // 去掉 "Bearer " 前缀，得到纯 token
            String token = header.substring(7);

            // 3. 验证 token 是否有效
            if (jwtUtil.validateToken(token)) {
                // 4. 从 token 中提取用户ID
                Long userId = jwtUtil.getUserIdFromToken(token);

                // 5. 创建认证对象，告诉 Spring "当前用户是 xxx"
                //    参数依次是：主体（用户ID）、凭证（null，不需要）、权限列表（空）
                UsernamePasswordAuthenticationToken authentication =
                        new UsernamePasswordAuthenticationToken(userId, null, new ArrayList<>());

                // 6. 将认证信息存入 SecurityContext
                //    后续的 Controller 可以通过 SecurityContextHolder 获取当前用户信息
                SecurityContextHolder.getContext().setAuthentication(authentication);
            }
        }

        // 7. 放行请求到下一个过滤器或目标 Controller
        //    不管认证是否成功，都要调用这个方法，否则请求会卡住
        filterChain.doFilter(request, response);
    }
}
