package com.appbackoffice.api.config;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface ConfigPackageRepository extends JpaRepository<ConfigPackageEntity, String> {

    List<ConfigPackageEntity> findByTenantIdOrderByUpdatedAtAsc(String tenantId);

    Optional<ConfigPackageEntity> findByIdAndTenantId(String id, String tenantId);
}