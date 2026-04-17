package com.example.demo.repository;

import com.example.demo.entity.VolunteerLocation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * 志愿者位置数据访问层 —— 负责和 volunteer_location 表交互
 *
 * 当 Redis 中没有志愿者位置数据时（如冷启动、Redis 重启），
 * 从数据库中查询作为降级方案。
 */
@Repository
public interface VolunteerLocationRepository extends JpaRepository<VolunteerLocation, Long> {

    /**
     * 查询所有在线的志愿者位置
     * 生成 SQL: SELECT * FROM volunteer_location WHERE is_online = true
     */
    List<VolunteerLocation> findByIsOnlineTrue();

    /**
     * 根据志愿者用户ID查询位置记录
     * 用于位置上报时的"更新或创建"逻辑
     */
    Optional<VolunteerLocation> findByVolunteerId(Long volunteerId);
}
