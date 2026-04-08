package com.appbackoffice.api.identity.service;

import com.appbackoffice.api.contract.ApiContractException;
import com.appbackoffice.api.contract.ErrorSeverity;
import com.appbackoffice.api.identity.entity.Tenant;
import com.appbackoffice.api.identity.entity.TenantStatus;
import com.appbackoffice.api.identity.repository.TenantRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;

@Service
public class TenantGuardService {

    private final TenantRepository tenantRepository;

    public TenantGuardService(TenantRepository tenantRepository) {
        this.tenantRepository = tenantRepository;
    }

    public Tenant requireActiveTenant(String tenantId) {
        Tenant tenant = tenantRepository.findById(tenantId)
                .orElseThrow(() -> new ApiContractException(
                        HttpStatus.NOT_FOUND,
                        "TENANT_NOT_FOUND",
                        "Tenant was not found",
                        ErrorSeverity.ERROR,
                        "Provide a valid tenant identifier before continuing.",
                        "tenantId=" + tenantId
                ));

        if (tenant.getStatus() == TenantStatus.ACTIVE) {
            return tenant;
        }

        throw new ApiContractException(
                HttpStatus.FORBIDDEN,
                "TENANT_INACTIVE",
                "Tenant is not active",
                ErrorSeverity.ERROR,
                "Reactivate the tenant before performing operational changes.",
                "tenantId=" + tenantId + ", status=" + tenant.getStatus()
        );
    }
}
