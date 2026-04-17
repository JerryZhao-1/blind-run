package com.example.demo.service;

import com.example.demo.dto.ReviewResponse;
import com.example.demo.entity.OrderReview;
import com.example.demo.entity.OrderStatus;
import com.example.demo.entity.RunOrder;
import com.example.demo.exception.OrderNotFoundException;
import com.example.demo.exception.OrderPermissionException;
import com.example.demo.exception.OrderStatusException;
import com.example.demo.exception.DuplicateOrderException;
import com.example.demo.repository.OrderReviewRepository;
import com.example.demo.repository.RunOrderRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 评价业务逻辑服务
 */
@Service
public class ReviewService {

    private final OrderReviewRepository orderReviewRepository;
    private final RunOrderRepository runOrderRepository;

    public ReviewService(OrderReviewRepository orderReviewRepository, RunOrderRepository runOrderRepository) {
        this.orderReviewRepository = orderReviewRepository;
        this.runOrderRepository = runOrderRepository;
    }

    /**
     * 创建评价（盲人对志愿者）
     */
    @Transactional
    public void createReview(Long orderId, Long userId, int rating, String comment) {
        RunOrder order = runOrderRepository.findById(orderId)
                .orElseThrow(() -> new OrderNotFoundException("订单不存在，ID: " + orderId));

        // 校验是订单的盲人用户
        if (!order.getBlindUser().getId().equals(userId)) {
            throw new OrderPermissionException("只有订单的盲人用户才能评价");
        }

        // 校验订单已完成
        if (order.getStatus() != OrderStatus.COMPLETED) {
            throw new OrderStatusException("只能对已完成的订单进行评价");
        }

        // 校验未评价过
        if (orderReviewRepository.existsByOrderId(orderId)) {
            throw new DuplicateOrderException("已评价过此订单");
        }

        // 校验评分范围
        if (rating < 1 || rating > 5) {
            throw new IllegalArgumentException("评分必须在1-5之间");
        }

        OrderReview review = new OrderReview();
        review.setOrderId(orderId);
        review.setReviewerId(userId);
        review.setRevieweeId(order.getVolunteer().getId());
        review.setRating(rating);
        review.setComment(comment);

        orderReviewRepository.save(review);
    }

    /**
     * 获取订单评价
     */
    public ReviewResponse getReview(Long orderId, Long userId) {
        RunOrder order = runOrderRepository.findById(orderId)
                .orElseThrow(() -> new OrderNotFoundException("订单不存在，ID: " + orderId));

        // 校验是订单相关方
        boolean isBlind = order.getBlindUser().getId().equals(userId);
        boolean isVolunteer = order.getVolunteer() != null && order.getVolunteer().getId().equals(userId);
        if (!isBlind && !isVolunteer) {
            throw new OrderPermissionException("您无权查看此订单评价");
        }

        return orderReviewRepository.findByOrderId(orderId)
                .map(review -> new ReviewResponse(
                        review.getOrderId(),
                        review.getRating(),
                        review.getComment(),
                        review.getCreatedAt() != null ? review.getCreatedAt().toString() : null
                ))
                .orElse(null);
    }
}
