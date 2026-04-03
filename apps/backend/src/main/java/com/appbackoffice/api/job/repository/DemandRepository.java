package com.appbackoffice.api.job.repository;

import com.appbackoffice.api.job.entity.Demand;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface DemandRepository extends JpaRepository<Demand, Long> {
    Optional<Demand> findByExternalIdAndTenantId(String externalId, String tenantId);
}
