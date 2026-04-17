package com.example.demo.controller;

import com.example.demo.dto.SetRoleRequest;
import com.example.demo.entity.BlindProfile;
import com.example.demo.entity.User;
import com.example.demo.entity.UserRole;
import com.example.demo.entity.VolunteerProfile;
import com.example.demo.exception.RoleAlreadySetException;
import com.example.demo.repository.BlindProfileRepository;
import com.example.demo.repository.UserRepository;
import com.example.demo.repository.VolunteerProfileRepository;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * 角色控制器 —— 处理用户身份选择
 *
 * POST /api/user/role → 设置用户角色（BLIND 或 VOLUNTEER）
 *
 * 规则：角色一旦选定不可修改，否则返回 409
 * 设置角色后自动创建对应的空白资料记录
 */
@RestController
@RequestMapping("/api/user")
public class RoleController {

    private final UserRepository userRepository;
    private final BlindProfileRepository blindProfileRepository;
    private final VolunteerProfileRepository volunteerProfileRepository;

    public RoleController(UserRepository userRepository,
                          BlindProfileRepository blindProfileRepository,
                          VolunteerProfileRepository volunteerProfileRepository) {
        this.userRepository = userRepository;
        this.blindProfileRepository = blindProfileRepository;
        this.volunteerProfileRepository = volunteerProfileRepository;
    }

    @PostMapping("/role")
    public ResponseEntity<?> setRole(@Valid @RequestBody SetRoleRequest request) {
        Long userId = (Long) SecurityContextHolder.getContext().getAuthentication().getPrincipal();

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("用户不存在"));

        if (user.getRole() != null && user.getRole() != UserRole.UNSET) {
            throw new RoleAlreadySetException("身份已设定，不可修改");
        }

        user.setRole(request.getRole());
        userRepository.save(user);

        // 创建对应的空白资料记录
        if (request.getRole() == UserRole.BLIND) {
            if (blindProfileRepository.findByUserId(userId).isEmpty()) {
                BlindProfile profile = new BlindProfile();
                profile.setUser(user);
                blindProfileRepository.save(profile);
            }
        } else if (request.getRole() == UserRole.VOLUNTEER) {
            if (volunteerProfileRepository.findByUserId(userId).isEmpty()) {
                VolunteerProfile profile = new VolunteerProfile();
                profile.setUser(user);
                volunteerProfileRepository.save(profile);
            }
        }

        return ResponseEntity.ok(Map.of("success", true, "role", user.getRole().name()));
    }
}
