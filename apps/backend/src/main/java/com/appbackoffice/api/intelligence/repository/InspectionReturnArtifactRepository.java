package com.appbackoffice.api.intelligence.repository;

import com.appbackoffice.api.intelligence.entity.InspectionReturnArtifactEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface InspectionReturnArtifactRepository extends JpaRepository<InspectionReturnArtifactEntity, Long> {
    Optional<InspectionReturnArtifactEntity> findTopByInspectionIdOrderByCreatedAtDesc(Long inspectionId);
    Optional<InspectionReturnArtifactEntity> findTopByTenantIdAndCaseIdOrderByCreatedAtDesc(String tenantId, Long caseId);
    long countByTenantId(String tenantId);
}
