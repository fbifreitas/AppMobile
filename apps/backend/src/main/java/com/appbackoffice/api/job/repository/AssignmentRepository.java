package com.appbackoffice.api.job.repository;

import com.appbackoffice.api.job.entity.Assignment;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface AssignmentRepository extends JpaRepository<Assignment, Long> {
    List<Assignment> findByJobId(Long jobId);
    Optional<Assignment> findTopByJobIdOrderByOfferedAtDesc(Long jobId);
}
