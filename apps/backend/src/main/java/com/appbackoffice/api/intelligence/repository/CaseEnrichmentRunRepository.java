package com.appbackoffice.api.intelligence.repository;

import com.appbackoffice.api.intelligence.entity.CaseEnrichmentRunEntity;
import com.appbackoffice.api.intelligence.entity.EnrichmentRunStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface CaseEnrichmentRunRepository extends JpaRepository<CaseEnrichmentRunEntity, Long> {
    Optional<CaseEnrichmentRunEntity> findTopByTenantIdAndCaseIdOrderByCreatedAtDesc(String tenantId, Long caseId);
    List<CaseEnrichmentRunEntity> findTop100ByTenantIdOrderByCreatedAtDesc(String tenantId);
    long countByTenantId(String tenantId);
    long countByTenantIdAndStatus(String tenantId, EnrichmentRunStatus status);
    long countByTenantIdAndCaseId(String tenantId, Long caseId);
}
