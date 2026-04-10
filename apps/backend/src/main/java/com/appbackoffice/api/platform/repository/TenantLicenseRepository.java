package com.appbackoffice.api.platform.repository;

import com.appbackoffice.api.platform.entity.TenantLicenseEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface TenantLicenseRepository extends JpaRepository<TenantLicenseEntity, Long> {
    Optional<TenantLicenseEntity> findByTenantId(String tenantId);

    List<TenantLicenseEntity> findByTenantIdIn(List<String> tenantIds);
}
