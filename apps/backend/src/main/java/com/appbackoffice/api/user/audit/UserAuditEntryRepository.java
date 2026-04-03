package com.appbackoffice.api.user.audit;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface UserAuditEntryRepository extends JpaRepository<UserAuditEntryEntity, String> {
    List<UserAuditEntryEntity> findTop50ByTenantIdOrderByCreatedAtDesc(String tenantId);

    List<UserAuditEntryEntity> findTop50ByTenantIdAndUserIdOrderByCreatedAtDesc(String tenantId, Long userId);
}