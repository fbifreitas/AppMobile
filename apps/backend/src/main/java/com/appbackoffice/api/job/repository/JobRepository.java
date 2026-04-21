package com.appbackoffice.api.job.repository;

import com.appbackoffice.api.job.entity.Job;
import com.appbackoffice.api.job.entity.JobStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface JobRepository extends JpaRepository<Job, Long> {
    Page<Job> findByTenantId(String tenantId, Pageable pageable);
    Page<Job> findByTenantIdAndStatus(String tenantId, JobStatus status, Pageable pageable);
    List<Job> findByAssignedToAndTenantId(Long assignedTo, String tenantId);
    List<Job> findByAssignedToAndTenantIdAndStatus(Long assignedTo, String tenantId, JobStatus status);
    Optional<Job> findTopByTenantIdAndCaseIdOrderByCreatedAtDesc(String tenantId, Long caseId);
}
