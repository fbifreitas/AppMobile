package com.appbackoffice.api.config;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ConfigAuditEntryRepository extends JpaRepository<ConfigAuditEntryEntity, String> {

    List<ConfigAuditEntryEntity> findTop20ByTenantIdOrderByCreatedAtDesc(String tenantId);
}