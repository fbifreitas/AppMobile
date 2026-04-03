package com.appbackoffice.api.integration.repository;

import com.appbackoffice.api.integration.entity.IntegrationDemandEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface IntegrationDemandRepository extends JpaRepository<IntegrationDemandEntity, String> {
    Optional<IntegrationDemandEntity> findByExternalId(String externalId);

    Optional<IntegrationDemandEntity> findByExternalIdAndTenantId(String externalId, String tenantId);
}
