package com.appbackoffice.api.job.repository;

import com.appbackoffice.api.job.entity.InspectionCase;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface CaseRepository extends JpaRepository<InspectionCase, Long> {
    List<InspectionCase> findByTenantId(String tenantId);
    boolean existsByTenantIdAndNumber(String tenantId, String number);
}
