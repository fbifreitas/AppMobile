package com.appbackoffice.api.integration;

import com.appbackoffice.api.contract.RequestContextValidator;
import com.appbackoffice.api.identity.entity.MembershipRole;
import com.appbackoffice.api.integration.dto.DemandCreateRequest;
import com.appbackoffice.api.integration.dto.DemandResponse;
import com.appbackoffice.api.integration.service.IntegrationDemandService;
import com.appbackoffice.api.security.RequiresTenantRole;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/integration/demands")
public class IntegrationDemandController {

    private final IntegrationDemandService integrationDemandService;

    public IntegrationDemandController(IntegrationDemandService integrationDemandService) {
        this.integrationDemandService = integrationDemandService;
    }

    @PostMapping
    @RequiresTenantRole({MembershipRole.TENANT_ADMIN, MembershipRole.COORDINATOR, MembershipRole.PLATFORM_ADMIN})
    public ResponseEntity<DemandResponse> createDemand(@RequestHeader("X-Correlation-Id") String correlationId,
                                                       @RequestHeader(value = "X-Actor-Role", required = false) String actorRole,
                                                       @Valid @RequestBody DemandCreateRequest request) {
        RequestContextValidator.requireCorrelationId(correlationId);
        DemandResponse response = integrationDemandService.createOrGet(request);
        HttpStatus status = response.created() ? HttpStatus.CREATED : HttpStatus.OK;
        return ResponseEntity.status(status).body(response);
    }

    @GetMapping("/{externalId}")
    @RequiresTenantRole({MembershipRole.TENANT_ADMIN, MembershipRole.COORDINATOR, MembershipRole.AUDITOR, MembershipRole.PLATFORM_ADMIN})
    public DemandResponse getDemandByExternalId(@PathVariable String externalId,
                                                @RequestParam String tenantId,
                                                @RequestHeader("X-Correlation-Id") String correlationId,
                                                @RequestHeader(value = "X-Actor-Role", required = false) String actorRole) {
        RequestContextValidator.requireCorrelationId(correlationId);
        return integrationDemandService.findByExternalId(externalId, tenantId);
    }
}
