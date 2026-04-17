package com.example.demo.controller;

import com.example.demo.dto.BlindProfileResponse;
import com.example.demo.dto.BlindProfileUpdateRequest;
import com.example.demo.service.BlindService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * 盲人资料控制器
 *
 * GET /api/blind/profile → 获取盲人资料
 * PUT /api/blind/profile → 更新盲人资料
 */
@RestController
@RequestMapping("/api/blind")
public class BlindController {

    private final BlindService blindService;

    public BlindController(BlindService blindService) {
        this.blindService = blindService;
    }

    @GetMapping("/profile")
    public ResponseEntity<BlindProfileResponse> getProfile() {
        Long userId = (Long) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        BlindProfileResponse profile = blindService.getProfile(userId);
        return ResponseEntity.ok(profile);
    }

    @PutMapping("/profile")
    public ResponseEntity<?> updateProfile(@RequestBody BlindProfileUpdateRequest request) {
        Long userId = (Long) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        BlindProfileResponse profile = blindService.updateProfile(userId, request);
        return ResponseEntity.ok(Map.of("success", true, "data", profile));
    }
}
