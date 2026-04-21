package com.appbackoffice.api.intelligence.repository;

import com.appbackoffice.api.intelligence.entity.FieldEvidenceRecordEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface FieldEvidenceRecordRepository extends JpaRepository<FieldEvidenceRecordEntity, Long> {
    List<FieldEvidenceRecordEntity> findByInspectionIdOrderByCreatedAtAsc(Long inspectionId);
    List<FieldEvidenceRecordEntity> findByTenantIdAndCaseIdOrderByCreatedAtAsc(String tenantId, Long caseId);
    void deleteByInspectionId(Long inspectionId);
    long countByTenantId(String tenantId);
}
