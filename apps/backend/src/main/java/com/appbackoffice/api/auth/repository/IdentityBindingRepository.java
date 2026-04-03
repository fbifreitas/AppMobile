package com.appbackoffice.api.auth.repository;

import com.appbackoffice.api.auth.entity.IdentityBindingEntity;
import com.appbackoffice.api.auth.entity.IdentityProviderType;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface IdentityBindingRepository extends JpaRepository<IdentityBindingEntity, String> {
    Optional<IdentityBindingEntity> findByProviderTypeAndProviderSubAndTenantId(
            IdentityProviderType providerType,
            String providerSub,
            String tenantId
    );

    boolean existsByUserIdAndProviderTypeAndTenantId(Long userId, IdentityProviderType providerType, String tenantId);
}
