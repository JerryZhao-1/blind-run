package com.example.demo.repository;

import com.example.demo.entity.BlindProfile;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface BlindProfileRepository extends JpaRepository<BlindProfile, Long> {
    Optional<BlindProfile> findByUserId(Long userId);
}
