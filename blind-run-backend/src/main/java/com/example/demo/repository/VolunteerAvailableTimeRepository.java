package com.example.demo.repository;

import com.example.demo.entity.VolunteerAvailableTime;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface VolunteerAvailableTimeRepository extends JpaRepository<VolunteerAvailableTime, Long> {
    void deleteByVolunteerId(Long volunteerId);
    List<VolunteerAvailableTime> findByVolunteerId(Long volunteerId);
}
