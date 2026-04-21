package com.appbackoffice.api.intelligence;

import com.appbackoffice.api.contract.RequestContextValidator;
import com.appbackoffice.api.identity.entity.MembershipRole;
import com.appbackoffice.api.intelligence.dto.EnrichmentRunResponse;
import com.appbackoffice.api.intelligence.dto.ExecutionPlanResponse;
import com.appbackoffice.api.intelligence.dto.TriggerEnrichmentResponse;
import com.appbackoffice.api.intelligence.service.IntelligenceBackofficeService;
import com.appbackoffice.api.security.RequiresTenantRole;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/backoffice/intelligence/cases")
public class IntelligenceBackofficeController {

    private final IntelligenceBackofficeService intelligenceBackofficeService;

    public IntelligenceBackofficeController(IntelligenceBackofficeService intelligenceBackofficeService) {
        this.intelligenceBackofficeService = intelligenceBackofficeService;
    }

    @PostMapping("/{caseId}/enrichment/trigger")
    @ResponseStatus(HttpStatus.ACCEPTED)
    @RequiresTenantRole({MembershipRole.TENANT_ADMIN, MembershipRole.COORDINATOR, MembershipRole.REGIONAL_COORD, MembershipRole.AUDITOR, MembershipRole.PLATFORM_ADMIN})
    public TriggerEnrichmentResponse triggerEnrichment(
            @PathVariable Long caseId,
            @RequestParam String tenantId,
            @RequestHeader("X-Correlation-Id") String correlationId,
            @RequestHeader(value = "X-Actor-Id", required = false) String actorId
    ) {
        RequestContextValidator.requireCorrelationId(correlationId);
        return intelligenceBackofficeService.triggerEnrichment(tenantId, caseId, actorId, correlationId);
    }

    @GetMapping("/{caseId}/enrichment-runs/latest")
    @RequiresTenantRole({MembershipRole.TENANT_ADMIN, MembershipRole.COORDINATOR, MembershipRole.REGIONAL_COORD, MembershipRole.AUDITOR, MembershipRole.PLATFORM_ADMIN})
    public EnrichmentRunResponse latestRun(
            @PathVariable Long caseId,
            @RequestParam String tenantId,
            @RequestHeader("X-Correlation-Id") String correlationId
    ) {
        RequestContextValidator.requireCorrelationId(correlationId);
        return intelligenceBackofficeService.getLatestRun(tenantId, caseId);
    }

    @GetMapping("/{caseId}/execution-plan/latest")
    @RequiresTenantRole({MembershipRole.TENANT_ADMIN, MembershipRole.COORDINATOR, MembershipRole.REGIONAL_COORD, MembershipRole.AUDITOR, MembershipRole.PLATFORM_ADMIN})
    public ExecutionPlanResponse latestExecutionPlan(
            @PathVariable Long caseId,
            @RequestParam String tenantId,
            @RequestHeader("X-Correlation-Id") String correlationId
    ) {
        RequestContextValidator.requireCorrelationId(correlationId);
        return intelligenceBackofficeService.getLatestExecutionPlan(tenantId, caseId);
    }
}
