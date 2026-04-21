package com.appbackoffice.api.intelligence.repository;

import com.appbackoffice.api.intelligence.entity.ExecutionPlanSnapshotEntity;
import com.appbackoffice.api.intelligence.entity.ExecutionPlanStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface ExecutionPlanSnapshotRepository extends JpaRepository<ExecutionPlanSnapshotEntity, Long> {
    Optional<ExecutionPlanSnapshotEntity> findTopByTenantIdAndCaseIdOrderByCreatedAtDesc(String tenantId, Long caseId);
    java.util.List<ExecutionPlanSnapshotEntity> findByTenantIdAndStatusInOrderByCreatedAtDesc(String tenantId, java.util.Collection<ExecutionPlanStatus> statuses);
    long countByTenantId(String tenantId);
    long countByTenantIdAndStatus(String tenantId, ExecutionPlanStatus status);
}
