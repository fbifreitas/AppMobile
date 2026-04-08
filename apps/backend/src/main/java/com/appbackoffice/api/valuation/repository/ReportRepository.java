package com.appbackoffice.api.valuation.repository;

import com.appbackoffice.api.valuation.entity.ReportEntity;
import com.appbackoffice.api.valuation.entity.ReportStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface ReportRepository extends JpaRepository<ReportEntity, Long> {
    Optional<ReportEntity> findByIdAndTenantId(Long id, String tenantId);

    Optional<ReportEntity> findByValuationProcessIdAndTenantId(Long valuationProcessId, String tenantId);

    List<ReportEntity> findByTenantIdOrderByUpdatedAtDescIdDesc(String tenantId);

    List<ReportEntity> findByTenantIdAndStatusOrderByUpdatedAtDescIdDesc(String tenantId, ReportStatus status);
}
