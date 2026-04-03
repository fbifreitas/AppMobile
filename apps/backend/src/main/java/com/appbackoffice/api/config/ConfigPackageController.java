package com.appbackoffice.api.config;

import com.appbackoffice.api.config.dto.*;
import com.appbackoffice.api.contract.RequestContextValidator;
import com.appbackoffice.api.identity.entity.MembershipRole;
import com.appbackoffice.api.security.RequiresTenantRole;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/backoffice/config")
public class ConfigPackageController {

    private final ConfigPackageService configPackageService;

    public ConfigPackageController(ConfigPackageService configPackageService) {
        this.configPackageService = configPackageService;
    }

    @GetMapping("/packages")
    @RequiresTenantRole({MembershipRole.TENANT_ADMIN, MembershipRole.COORDINATOR, MembershipRole.AUDITOR, MembershipRole.PLATFORM_ADMIN})
    public ConfigPackagesResponse listPackages(
            @RequestParam String tenantId,
            @RequestHeader("X-Correlation-Id") String correlationId,
            @RequestParam(defaultValue = "tenant_admin") String actorRole
    ) {
        RequestContextValidator.requireCorrelationId(correlationId);
        return configPackageService.listPackages(tenantId, ActorRole.valueOf(actorRole.toUpperCase()));
    }

    @PostMapping("/packages")
    @RequiresTenantRole({MembershipRole.TENANT_ADMIN, MembershipRole.COORDINATOR, MembershipRole.PLATFORM_ADMIN})
    public ResponseEntity<ConfigMutationResponse> publish(
            @RequestHeader("X-Correlation-Id") String correlationId,
            @Valid @RequestBody ConfigPackagePublishRequest request
    ) {
        RequestContextValidator.requireCorrelationId(correlationId);
        return ResponseEntity.status(HttpStatus.CREATED).body(configPackageService.publish(request));
    }

    @PostMapping("/packages/approve")
    @RequiresTenantRole({MembershipRole.TENANT_ADMIN, MembershipRole.PLATFORM_ADMIN})
    public ConfigMutationResponse approve(
            @RequestHeader("X-Correlation-Id") String correlationId,
            @Valid @RequestBody ConfigPackageActionRequest request
    ) {
        RequestContextValidator.requireCorrelationId(correlationId);
        return configPackageService.approve(request);
    }

    @PostMapping("/packages/rollback")
    @RequiresTenantRole({MembershipRole.TENANT_ADMIN, MembershipRole.PLATFORM_ADMIN})
    public ConfigMutationResponse rollback(
            @RequestHeader("X-Correlation-Id") String correlationId,
            @Valid @RequestBody ConfigPackageActionRequest request
    ) {
        RequestContextValidator.requireCorrelationId(correlationId);
        return configPackageService.rollback(request);
    }

    @GetMapping("/resolve")
    @RequiresTenantRole({MembershipRole.TENANT_ADMIN, MembershipRole.COORDINATOR, MembershipRole.AUDITOR, MembershipRole.PLATFORM_ADMIN})
    public ConfigResolveResponse resolve(
            @RequestParam String tenantId,
            @RequestHeader("X-Correlation-Id") String correlationId,
            @RequestParam(required = false) String unitId,
            @RequestParam(required = false) String roleId,
            @RequestParam(required = false) String userId,
            @RequestParam(required = false) String deviceId,
            @RequestParam(defaultValue = "tenant_admin") String actorRole
    ) {
        RequestContextValidator.requireCorrelationId(correlationId);
        return configPackageService.resolve(
                tenantId,
                unitId,
                roleId,
                userId,
                deviceId,
                ActorRole.valueOf(actorRole.toUpperCase())
        );
    }

    @GetMapping("/audit")
    @RequiresTenantRole({MembershipRole.TENANT_ADMIN, MembershipRole.AUDITOR, MembershipRole.PLATFORM_ADMIN})
    public ConfigAuditResponse audit(
            @RequestParam String tenantId,
            @RequestHeader("X-Correlation-Id") String correlationId,
            @RequestParam(defaultValue = "tenant_admin") String actorRole
    ) {
        RequestContextValidator.requireCorrelationId(correlationId);
        return configPackageService.listAudit(tenantId, ActorRole.valueOf(actorRole.toUpperCase()));
    }
}