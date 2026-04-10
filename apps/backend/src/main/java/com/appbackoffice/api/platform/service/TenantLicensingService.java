package com.appbackoffice.api.platform.service;

import com.appbackoffice.api.contract.ApiContractException;
import com.appbackoffice.api.contract.ErrorSeverity;
import com.appbackoffice.api.identity.entity.MembershipStatus;
import com.appbackoffice.api.identity.repository.MembershipRepository;
import com.appbackoffice.api.platform.dto.TenantLicenseResponse;
import com.appbackoffice.api.platform.entity.LicenseModel;
import com.appbackoffice.api.platform.entity.TenantLicenseEntity;
import com.appbackoffice.api.platform.repository.TenantLicenseRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;

@Service
public class TenantLicensingService {

    private final TenantLicenseRepository tenantLicenseRepository;
    private final MembershipRepository membershipRepository;

    public TenantLicensingService(TenantLicenseRepository tenantLicenseRepository,
                                  MembershipRepository membershipRepository) {
        this.tenantLicenseRepository = tenantLicenseRepository;
        this.membershipRepository = membershipRepository;
    }

    public void ensureSeatAvailable(String tenantId) {
        TenantLicenseEntity license = tenantLicenseRepository.findByTenantId(tenantId).orElse(null);
        if (license == null) {
            return;
        }

        long consumed = consumedSeats(tenantId);
        if (license.isHardLimitEnforced() && consumed >= license.getContractedSeats()) {
            throw new ApiContractException(
                    HttpStatus.CONFLICT,
                    "LICENSE_SEAT_LIMIT_REACHED",
                    "Tenant excedeu o limite contratado de usuarios",
                    ErrorSeverity.ERROR,
                    "Ajuste a licenca do tenant ou revogue usuarios ativos antes de continuar.",
                    "tenantId=" + tenantId + ", consumed=" + consumed + ", contracted=" + license.getContractedSeats()
            );
        }
    }

    public long consumedSeats(String tenantId) {
        return membershipRepository.countByTenant_IdAndStatus(tenantId, MembershipStatus.ACTIVE);
    }

    public TenantLicenseResponse toResponse(String tenantId, TenantLicenseEntity entity) {
        long consumed = consumedSeats(tenantId);
        if (entity == null) {
            return new TenantLicenseResponse(
                    tenantId,
                    LicenseModel.PER_USER.name(),
                    0,
                    0,
                    false,
                    consumed,
                    0,
                    false
            );
        }

        long available = Math.max(entity.getContractedSeats() - consumed, 0);
        boolean overLimit = consumed > entity.getContractedSeats();
        return new TenantLicenseResponse(
                tenantId,
                entity.getLicenseModel().name(),
                entity.getContractedSeats(),
                entity.getWarningSeats(),
                entity.isHardLimitEnforced(),
                consumed,
                available,
                overLimit
        );
    }
}
