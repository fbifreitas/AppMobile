package com.appbackoffice.api.platform;

import com.appbackoffice.api.contract.RequestContextValidator;
import com.appbackoffice.api.identity.entity.MembershipRole;
import com.appbackoffice.api.platform.dto.TenantApplicationResponse;
import com.appbackoffice.api.platform.dto.TenantAdminHandoffResponse;
import com.appbackoffice.api.platform.dto.TenantLicenseResponse;
import com.appbackoffice.api.platform.dto.TenantPlatformListResponse;
import com.appbackoffice.api.platform.dto.UpsertTenantAdminHandoffRequest;
import com.appbackoffice.api.platform.dto.UpsertTenantApplicationRequest;
import com.appbackoffice.api.platform.dto.UpsertTenantLicenseRequest;
import com.appbackoffice.api.platform.service.PlatformTenantService;
import com.appbackoffice.api.security.RequiresTenantRole;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/backoffice/platform/tenants")
@RequiresTenantRole({MembershipRole.PLATFORM_ADMIN})
public class PlatformTenantController {

    private final PlatformTenantService platformTenantService;

    public PlatformTenantController(PlatformTenantService platformTenantService) {
        this.platformTenantService = platformTenantService;
    }

    @GetMapping
    public TenantPlatformListResponse list(@RequestHeader("X-Correlation-Id") String correlationId,
                                           @RequestParam(required = false) String q,
                                           @RequestParam(required = false) String status) {
        RequestContextValidator.requireCorrelationId(correlationId);
        return platformTenantService.listTenants(q, status);
    }

    @GetMapping("/{tenantId}/application")
    public TenantApplicationResponse getApplication(@PathVariable String tenantId,
                                                    @RequestHeader("X-Correlation-Id") String correlationId) {
        RequestContextValidator.requireCorrelationId(correlationId);
        return platformTenantService.getApplication(tenantId);
    }

    @PutMapping("/{tenantId}/application")
    public TenantApplicationResponse upsertApplication(@PathVariable String tenantId,
                                                       @RequestHeader("X-Correlation-Id") String correlationId,
                                                       @Valid @RequestBody UpsertTenantApplicationRequest request) {
        RequestContextValidator.requireCorrelationId(correlationId);
        return platformTenantService.upsertApplication(tenantId, request);
    }

    @GetMapping("/{tenantId}/license")
    public TenantLicenseResponse getLicense(@PathVariable String tenantId,
                                            @RequestHeader("X-Correlation-Id") String correlationId) {
        RequestContextValidator.requireCorrelationId(correlationId);
        return platformTenantService.getLicense(tenantId);
    }

    @PutMapping("/{tenantId}/license")
    public TenantLicenseResponse upsertLicense(@PathVariable String tenantId,
                                               @RequestHeader("X-Correlation-Id") String correlationId,
                                               @Valid @RequestBody UpsertTenantLicenseRequest request) {
        RequestContextValidator.requireCorrelationId(correlationId);
        return platformTenantService.upsertLicense(tenantId, request);
    }

    @GetMapping("/{tenantId}/admin-handoff")
    public TenantAdminHandoffResponse getAdminHandoff(@PathVariable String tenantId,
                                                      @RequestHeader("X-Correlation-Id") String correlationId) {
        RequestContextValidator.requireCorrelationId(correlationId);
        return platformTenantService.getAdminHandoff(tenantId);
    }

    @PutMapping("/{tenantId}/admin-handoff")
    public TenantAdminHandoffResponse upsertAdminHandoff(@PathVariable String tenantId,
                                                         @RequestHeader("X-Correlation-Id") String correlationId,
                                                         @Valid @RequestBody UpsertTenantAdminHandoffRequest request) {
        RequestContextValidator.requireCorrelationId(correlationId);
        return platformTenantService.upsertAdminHandoff(tenantId, request);
    }
}
