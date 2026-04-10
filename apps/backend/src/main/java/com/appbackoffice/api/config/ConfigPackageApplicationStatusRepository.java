package com.appbackoffice.api.config;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ConfigPackageApplicationStatusRepository extends JpaRepository<ConfigPackageApplicationStatusEntity, Long> {

    List<ConfigPackageApplicationStatusEntity> findTop100ByTenantIdOrderByUpdatedAtDescIdDesc(String tenantId);

    List<ConfigPackageApplicationStatusEntity> findTop100ByTenantIdAndPackageVersionOrderByUpdatedAtDescIdDesc(
            String tenantId,
            String packageVersion
    );
}
