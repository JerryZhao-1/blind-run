package com.example.demo.controller;

import com.example.demo.dto.VolunteerProfileResponse;
import com.example.demo.dto.VolunteerProfileUpdateRequest;
import com.example.demo.dto.VolunteerLocationRequest;
import com.example.demo.service.VolunteerLocationService;
import com.example.demo.service.VolunteerService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.Map;

/**
 * 志愿者控制器
 *
 * GET    /api/volunteer/profile                → 获取志愿者资料
 * PUT    /api/volunteer/profile                → 更新志愿者资料
 * POST   /api/volunteer/verification           → 上传资质证件
 * GET    /api/volunteer/verification/status     → 获取认证状态
 * POST   /api/volunteer/location               → 上报实时位置
 */
@RestController
@RequestMapping("/api/volunteer")
public class VolunteerController {

    private final VolunteerLocationService volunteerLocationService;
    private final VolunteerService volunteerService;

    public VolunteerController(VolunteerLocationService volunteerLocationService,
                               VolunteerService volunteerService) {
        this.volunteerLocationService = volunteerLocationService;
        this.volunteerService = volunteerService;
    }

    @GetMapping("/profile")
    public ResponseEntity<VolunteerProfileResponse> getProfile() {
        Long userId = (Long) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        VolunteerProfileResponse profile = volunteerService.getProfile(userId);
        return ResponseEntity.ok(profile);
    }

    @PutMapping("/profile")
    public ResponseEntity<?> updateProfile(@RequestBody VolunteerProfileUpdateRequest request) {
        Long userId = (Long) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        VolunteerProfileResponse profile = volunteerService.updateProfile(userId, request);
        return ResponseEntity.ok(Map.of("success", true, "data", profile));
    }

    @PostMapping("/verification")
    public ResponseEntity<?> submitVerification(@RequestParam("file") MultipartFile file) {
        Long userId = (Long) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        String status = volunteerService.submitVerification(userId, file);
        return ResponseEntity.ok(Map.of("success", true, "status", status));
    }

    @GetMapping("/verification/status")
    public ResponseEntity<?> getVerificationStatus() {
        Long userId = (Long) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        String status = volunteerService.getVerificationStatus(userId);
        return ResponseEntity.ok(Map.of("status", status));
    }

    @PostMapping("/location")
    public ResponseEntity<?> updateLocation(@Valid @RequestBody VolunteerLocationRequest request) {
        Long userId = (Long) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        volunteerLocationService.updateLocation(
                userId,
                request.getLatitude(),
                request.getLongitude(),
                request.getIsOnline()
        );
        return ResponseEntity.ok(Map.of("success", true));
    }
}
