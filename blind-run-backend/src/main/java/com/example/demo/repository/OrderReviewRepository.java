package com.example.demo.repository;

import com.example.demo.entity.OrderReview;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface OrderReviewRepository extends JpaRepository<OrderReview, Long> {
    boolean existsByOrderId(Long orderId);
    Optional<OrderReview> findByOrderId(Long orderId);
}
