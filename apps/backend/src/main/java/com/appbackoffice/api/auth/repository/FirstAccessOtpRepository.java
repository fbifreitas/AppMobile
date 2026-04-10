package com.appbackoffice.api.auth.repository;

import com.appbackoffice.api.auth.entity.FirstAccessOtpEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface FirstAccessOtpRepository extends JpaRepository<FirstAccessOtpEntity, String> {
    Optional<FirstAccessOtpEntity> findByIdAndTenantId(String id, String tenantId);
}
