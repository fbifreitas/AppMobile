package com.appbackoffice.api.platform.repository;

import com.appbackoffice.api.platform.entity.TenantApplicationEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface TenantApplicationRepository extends JpaRepository<TenantApplicationEntity, Long> {
    Optional<TenantApplicationEntity> findByTenantId(String tenantId);

    List<TenantApplicationEntity> findByTenantIdIn(List<String> tenantIds);
}
