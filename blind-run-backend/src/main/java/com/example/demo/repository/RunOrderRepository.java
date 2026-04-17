package com.example.demo.repository;

import com.example.demo.entity.OrderStatus;
import com.example.demo.entity.RunOrder;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

/**
 * 订单数据访问层 —— 负责和 run_order 表交互
 */
@Repository
public interface RunOrderRepository extends JpaRepository<RunOrder, Long> {

    /** 查询某个用户是否有进行中的订单 */
    boolean existsByBlindUserIdAndStatusIn(Long blindUserId, List<OrderStatus> statuses);

    /** 根据订单ID和状态查询订单 */
    Optional<RunOrder> findByIdAndStatus(Long id, OrderStatus status);

    /** 根据ID查询订单，同时加载盲人用户信息（避免异步线程懒加载异常） */
    @Query("SELECT o FROM RunOrder o JOIN FETCH o.blindUser WHERE o.id = :id")
    Optional<RunOrder> findByIdWithBlindUser(@Param("id") Long id);

    /** 根据ID查询订单，同时加载盲人用户和志愿者信息 */
    @Query("SELECT o FROM RunOrder o JOIN FETCH o.blindUser LEFT JOIN FETCH o.volunteer WHERE o.id = :id")
    Optional<RunOrder> findByIdWithUsers(@Param("id") Long id);

    /** 查询超时未完成的订单（供定时任务使用） */
    @Query("SELECT o FROM RunOrder o WHERE o.status = 'IN_PROGRESS' AND o.plannedEndTime < :now")
    List<RunOrder> findTimedOutOrders(@Param("now") LocalDateTime now);

    /** 分页查询盲人用户的所有订单 */
    Page<RunOrder> findByBlindUserId(Long blindUserId, Pageable pageable);

    /** 分页查询盲人用户指定状态的订单 */
    Page<RunOrder> findByBlindUserIdAndStatusIn(Long blindUserId, List<OrderStatus> statuses, Pageable pageable);

    /** 分页查询志愿者的所有订单 */
    Page<RunOrder> findByVolunteerId(Long volunteerId, Pageable pageable);

    /** 分页查询志愿者指定状态的订单 */
    Page<RunOrder> findByVolunteerIdAndStatusIn(Long volunteerId, List<OrderStatus> statuses, Pageable pageable);

    /** 查询指定状态的所有订单（含盲人用户信息） */
    @Query("SELECT o FROM RunOrder o JOIN FETCH o.blindUser WHERE o.status = :status")
    List<RunOrder> findByStatus(@Param("status") OrderStatus status);
}
