package com.appbackoffice.api.auth.repository;

import com.appbackoffice.api.auth.entity.UserCredentialEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface UserCredentialRepository extends JpaRepository<UserCredentialEntity, Long> {
    Optional<UserCredentialEntity> findByTenantIdAndUserId(String tenantId, Long userId);
}
