package com.appbackoffice.api.valuation.repository;

import com.appbackoffice.api.valuation.entity.ValuationProcessEntity;
import com.appbackoffice.api.valuation.entity.ValuationProcessStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface ValuationProcessRepository extends JpaRepository<ValuationProcessEntity, Long> {
    Optional<ValuationProcessEntity> findByIdAndTenantId(Long id, String tenantId);

    Optional<ValuationProcessEntity> findByInspectionIdAndTenantId(Long inspectionId, String tenantId);

    List<ValuationProcessEntity> findByTenantIdOrderByUpdatedAtDescIdDesc(String tenantId);

    List<ValuationProcessEntity> findByTenantIdAndStatusOrderByUpdatedAtDescIdDesc(String tenantId, ValuationProcessStatus status);
}
