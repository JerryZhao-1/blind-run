package com.example.demo.service;

import com.example.demo.dto.BlindProfileResponse;
import com.example.demo.dto.BlindProfileUpdateRequest;
import com.example.demo.entity.BlindProfile;
import com.example.demo.entity.User;
import com.example.demo.entity.UserRole;
import com.example.demo.exception.PermissionDeniedException;
import com.example.demo.exception.ResourceNotFoundException;
import com.example.demo.repository.BlindProfileRepository;
import com.example.demo.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 盲人资料业务逻辑服务
 */
@Service
public class BlindService {

    private final BlindProfileRepository blindProfileRepository;
    private final UserRepository userRepository;

    public BlindService(BlindProfileRepository blindProfileRepository, UserRepository userRepository) {
        this.blindProfileRepository = blindProfileRepository;
        this.userRepository = userRepository;
    }

    /**
     * 获取盲人资料
     */
    public BlindProfileResponse getProfile(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("用户不存在"));

        if (user.getRole() != UserRole.BLIND) {
            throw new PermissionDeniedException("仅盲人用户可访问此接口");
        }

        BlindProfile profile = blindProfileRepository.findByUserId(userId)
                .orElseThrow(() -> new ResourceNotFoundException("盲人资料不存在"));

        return new BlindProfileResponse(
                profile.getName(),
                profile.getEmergencyContactName(),
                profile.getEmergencyContactPhone(),
                profile.getEmergencyContactRelation(),
                profile.getRunningPace(),
                profile.getSpecialNeeds()
        );
    }

    /**
     * 更新盲人资料（upsert）
     */
    @Transactional
    public BlindProfileResponse updateProfile(Long userId, BlindProfileUpdateRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("用户不存在"));

        if (user.getRole() != UserRole.BLIND) {
            throw new PermissionDeniedException("仅盲人用户可访问此接口");
        }

        BlindProfile profile = blindProfileRepository.findByUserId(userId)
                .orElseGet(() -> {
                    BlindProfile p = new BlindProfile();
                    p.setUser(user);
                    return p;
                });

        profile.setName(request.getName());
        profile.setEmergencyContactName(request.getEmergencyContactName());
        profile.setEmergencyContactPhone(request.getEmergencyContactPhone());
        profile.setEmergencyContactRelation(request.getEmergencyContactRelation());
        profile.setRunningPace(request.getRunningPace());
        profile.setSpecialNeeds(request.getSpecialNeeds());

        blindProfileRepository.save(profile);

        return new BlindProfileResponse(
                profile.getName(),
                profile.getEmergencyContactName(),
                profile.getEmergencyContactPhone(),
                profile.getEmergencyContactRelation(),
                profile.getRunningPace(),
                profile.getSpecialNeeds()
        );
    }
}
