package com.appbackoffice.api.mobile.repository;

import com.appbackoffice.api.mobile.entity.InspectionEntity;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface InspectionRepository extends JpaRepository<InspectionEntity, Long>, JpaSpecificationExecutor<InspectionEntity> {

    Optional<InspectionEntity> findByTenantIdAndIdempotencyKey(String tenantId, String idempotencyKey);

    Optional<InspectionEntity> findByIdAndTenantId(Long id, String tenantId);
}
