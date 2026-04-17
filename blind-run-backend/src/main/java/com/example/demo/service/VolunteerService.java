package com.example.demo.service;

import com.example.demo.dto.VolunteerAvailableTimeSlot;
import com.example.demo.dto.VolunteerProfileResponse;
import com.example.demo.dto.VolunteerProfileUpdateRequest;
import com.example.demo.entity.User;
import com.example.demo.entity.UserRole;
import com.example.demo.entity.VerificationStatus;
import com.example.demo.entity.VolunteerAvailableTime;
import com.example.demo.entity.VolunteerProfile;
import com.example.demo.exception.PermissionDeniedException;
import com.example.demo.exception.ResourceNotFoundException;
import com.example.demo.repository.VolunteerAvailableTimeRepository;
import com.example.demo.repository.VolunteerProfileRepository;
import com.example.demo.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

/**
 * 志愿者业务逻辑服务
 */
@Service
public class VolunteerService {

    private final VolunteerProfileRepository volunteerProfileRepository;
    private final VolunteerAvailableTimeRepository volunteerAvailableTimeRepository;
    private final UserRepository userRepository;
    private final FileStorageService fileStorageService;

    public VolunteerService(VolunteerProfileRepository volunteerProfileRepository,
                            VolunteerAvailableTimeRepository volunteerAvailableTimeRepository,
                            UserRepository userRepository,
                            FileStorageService fileStorageService) {
        this.volunteerProfileRepository = volunteerProfileRepository;
        this.volunteerAvailableTimeRepository = volunteerAvailableTimeRepository;
        this.userRepository = userRepository;
        this.fileStorageService = fileStorageService;
    }

    /**
     * 获取志愿者资料
     */
    public VolunteerProfileResponse getProfile(Long userId) {
        checkVolunteerRole(userId);

        VolunteerProfile profile = volunteerProfileRepository.findByUserId(userId)
                .orElseThrow(() -> new ResourceNotFoundException("志愿者资料不存在"));

        List<VolunteerAvailableTime> times = volunteerAvailableTimeRepository.findByVolunteerId(userId);
        List<VolunteerAvailableTimeSlot> slots = times.stream().map(t -> {
            VolunteerAvailableTimeSlot slot = new VolunteerAvailableTimeSlot();
            slot.setDayOfWeek(t.getDayOfWeek());
            slot.setStartTime(t.getStartTime());
            slot.setEndTime(t.getEndTime());
            return slot;
        }).toList();

        return new VolunteerProfileResponse(
                profile.getName(),
                profile.getVerificationStatus().name(),
                slots
        );
    }

    /**
     * 更新志愿者资料（name + 可用时间段替换）
     */
    @Transactional
    public VolunteerProfileResponse updateProfile(Long userId, VolunteerProfileUpdateRequest request) {
        checkVolunteerRole(userId);

        VolunteerProfile profile = volunteerProfileRepository.findByUserId(userId)
                .orElseThrow(() -> new ResourceNotFoundException("志愿者资料不存在"));

        profile.setName(request.getName());
        volunteerProfileRepository.save(profile);

        // 替换可用时间段：先删后插
        volunteerAvailableTimeRepository.deleteByVolunteerId(userId);
        if (request.getAvailableTimeSlots() != null) {
            for (VolunteerAvailableTimeSlot slot : request.getAvailableTimeSlots()) {
                VolunteerAvailableTime time = new VolunteerAvailableTime();
                time.setVolunteerId(userId);
                time.setDayOfWeek(slot.getDayOfWeek());
                time.setStartTime(slot.getStartTime());
                time.setEndTime(slot.getEndTime());
                volunteerAvailableTimeRepository.save(time);
            }
        }

        return getProfile(userId);
    }

    /**
     * 上传资质证件（v1.0 自动审核通过）
     */
    @Transactional
    public String submitVerification(Long userId, MultipartFile file) {
        checkVolunteerRole(userId);

        VolunteerProfile profile = volunteerProfileRepository.findByUserId(userId)
                .orElseThrow(() -> new ResourceNotFoundException("志愿者资料不存在"));

        String filePath = fileStorageService.store(file);

        profile.setVerificationDocUrl(filePath);
        profile.setVerificationStatus(VerificationStatus.APPROVED);
        profile.setVerified(true);
        volunteerProfileRepository.save(profile);

        return VerificationStatus.APPROVED.name();
    }

    /**
     * 获取认证状态
     */
    public String getVerificationStatus(Long userId) {
        checkVolunteerRole(userId);

        VolunteerProfile profile = volunteerProfileRepository.findByUserId(userId)
                .orElseThrow(() -> new ResourceNotFoundException("志愿者资料不存在"));

        return profile.getVerificationStatus().name();
    }

    private void checkVolunteerRole(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("用户不存在"));
        if (user.getRole() != UserRole.VOLUNTEER) {
            throw new PermissionDeniedException("仅志愿者用户可访问此接口");
        }
    }
}
