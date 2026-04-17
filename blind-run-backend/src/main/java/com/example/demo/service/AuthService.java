package com.example.demo.service;

import com.example.demo.dto.LoginResponse;
import com.example.demo.entity.User;
import com.example.demo.entity.UserRole;
import com.example.demo.exception.AuthException;
import com.example.demo.repository.UserRepository;
import com.example.demo.util.JwtUtil;
import org.springframework.stereotype.Service;

/**
 * 认证业务逻辑服务 —— 处理 "发送验证码" 和 "验证码登录" 的核心逻辑
 */
@Service
public class AuthService {

    private final UserRepository userRepository;
    private final JwtUtil jwtUtil;
    private final SmsService smsService;
    private final VerificationCodeService verificationCodeService;

    public AuthService(UserRepository userRepository,
                       JwtUtil jwtUtil,
                       SmsService smsService,
                       VerificationCodeService verificationCodeService) {
        this.userRepository = userRepository;
        this.jwtUtil = jwtUtil;
        this.smsService = smsService;
        this.verificationCodeService = verificationCodeService;
    }

    /**
     * 发送验证码
     */
    public void sendVerificationCode(String phone) {
        if (phone == null || !phone.matches("^\\d{11}$")) {
            throw new AuthException("手机号格式不正确，请输入11位数字");
        }

        String code = verificationCodeService.generateAndStoreCode(phone);
        smsService.sendVerificationCode(phone, code);
    }

    /**
     * 验证码登录 —— 验证码正确则自动登录，新用户自动注册
     */
    public LoginResponse verifyCodeAndLogin(String phone, String code) {
        boolean isValid = verificationCodeService.verifyCode(phone, code);
        if (!isValid) {
            throw new AuthException("验证码错误或已过期");
        }

        User user = userRepository.findByPhone(phone).orElseGet(() -> {
            User newUser = new User();
            newUser.setPhone(phone);
            newUser.setName("用户" + phone.substring(Math.max(0, phone.length() - 4)));
            return userRepository.save(newUser);
        });

        String token = jwtUtil.generateToken(user.getId());
        String role = user.getRole() != null ? user.getRole().name() : UserRole.UNSET.name();

        return new LoginResponse(token, user.getId(), role);
    }

    /**
     * 获取当前用户信息
     */
    public User getCurrentUser(Long userId) {
        return userRepository.findById(userId)
                .orElseThrow(() -> new AuthException("用户不存在"));
    }
}
