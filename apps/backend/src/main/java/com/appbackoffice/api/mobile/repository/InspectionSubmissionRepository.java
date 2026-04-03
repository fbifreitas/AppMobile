package com.appbackoffice.api.mobile.repository;

import com.appbackoffice.api.mobile.entity.InspectionSubmissionEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface InspectionSubmissionRepository extends JpaRepository<InspectionSubmissionEntity, Long> {
    Optional<InspectionSubmissionEntity> findByTenantIdAndIdempotencyKey(String tenantId, String idempotencyKey);
}
