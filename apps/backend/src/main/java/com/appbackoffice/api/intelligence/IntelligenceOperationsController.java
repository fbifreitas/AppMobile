package com.appbackoffice.api.intelligence;

import com.appbackoffice.api.contract.RequestContextValidator;
import com.appbackoffice.api.identity.entity.MembershipRole;
import com.appbackoffice.api.intelligence.dto.IntelligenceAnalyticsReadinessResponse;
import com.appbackoffice.api.intelligence.dto.ManualResolutionQueueResponse;
import com.appbackoffice.api.intelligence.dto.CaptureGatePolicyResponse;
import com.appbackoffice.api.intelligence.dto.ExecutionPlanResponse;
import com.appbackoffice.api.intelligence.dto.ManualSubtypeResolutionRequest;
import com.appbackoffice.api.intelligence.dto.NormativeMatrixResponse;
import com.appbackoffice.api.intelligence.dto.OperationalReferenceProfilesResponse;
import com.appbackoffice.api.intelligence.dto.OperationalReferenceRebuildResponse;
import com.appbackoffice.api.intelligence.dto.ReportBasisResponse;
import com.appbackoffice.api.intelligence.dto.ResolvePreviewResponse;
import com.appbackoffice.api.intelligence.entity.OperationalReferenceProfileMutationRequest;
import com.appbackoffice.api.intelligence.service.IntelligenceAnalyticsReadinessQueryService;
import com.appbackoffice.api.intelligence.service.ManualResolutionQueueQueryService;
import com.appbackoffice.api.intelligence.service.ManualResolutionCommandService;
import com.appbackoffice.api.intelligence.service.CaptureGatePolicyService;
import com.appbackoffice.api.intelligence.service.NormativeMatrixService;
import com.appbackoffice.api.intelligence.service.OperationalReferenceProfileCommandService;
import com.appbackoffice.api.intelligence.service.OperationalReferenceProfilesQueryService;
import com.appbackoffice.api.intelligence.service.OperationalReferenceRebuildService;
import com.appbackoffice.api.intelligence.service.ReportBasisQueryService;
import com.appbackoffice.api.intelligence.service.ResolvePreviewQueryService;
import jakarta.validation.Valid;
import com.appbackoffice.api.security.RequiresTenantRole;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/backoffice/intelligence")
public class IntelligenceOperationsController {

    private final ManualResolutionQueueQueryService manualResolutionQueueQueryService;
    private final ManualResolutionCommandService manualResolutionCommandService;
    private final ReportBasisQueryService reportBasisQueryService;
    private final IntelligenceAnalyticsReadinessQueryService intelligenceAnalyticsReadinessQueryService;
    private final OperationalReferenceProfilesQueryService operationalReferenceProfilesQueryService;
    private final OperationalReferenceRebuildService operationalReferenceRebuildService;
    private final OperationalReferenceProfileCommandService operationalReferenceProfileCommandService;
    private final CaptureGatePolicyService captureGatePolicyService;
    private final NormativeMatrixService normativeMatrixService;
    private final ResolvePreviewQueryService resolvePreviewQueryService;

    public IntelligenceOperationsController(ManualResolutionQueueQueryService manualResolutionQueueQueryService,
                                            ManualResolutionCommandService manualResolutionCommandService,
                                            ReportBasisQueryService reportBasisQueryService,
                                            IntelligenceAnalyticsReadinessQueryService intelligenceAnalyticsReadinessQueryService,
                                            OperationalReferenceProfilesQueryService operationalReferenceProfilesQueryService,
                                            OperationalReferenceRebuildService operationalReferenceRebuildService,
                                            OperationalReferenceProfileCommandService operationalReferenceProfileCommandService,
                                            CaptureGatePolicyService captureGatePolicyService,
                                            NormativeMatrixService normativeMatrixService,
                                            ResolvePreviewQueryService resolvePreviewQueryService) {
        this.manualResolutionQueueQueryService = manualResolutionQueueQueryService;
        this.manualResolutionCommandService = manualResolutionCommandService;
        this.reportBasisQueryService = reportBasisQueryService;
        this.intelligenceAnalyticsReadinessQueryService = intelligenceAnalyticsReadinessQueryService;
        this.operationalReferenceProfilesQueryService = operationalReferenceProfilesQueryService;
        this.operationalReferenceRebuildService = operationalReferenceRebuildService;
        this.operationalReferenceProfileCommandService = operationalReferenceProfileCommandService;
        this.captureGatePolicyService = captureGatePolicyService;
        this.normativeMatrixService = normativeMatrixService;
        this.resolvePreviewQueryService = resolvePreviewQueryService;
    }

    @GetMapping("/manual-resolution-queue")
    @RequiresTenantRole({MembershipRole.TENANT_ADMIN, MembershipRole.COORDINATOR, MembershipRole.REGIONAL_COORD, MembershipRole.AUDITOR, MembershipRole.PLATFORM_ADMIN})
    public ManualResolutionQueueResponse manualResolutionQueue(
            @RequestParam String tenantId,
            @RequestParam(defaultValue = "20") int limit,
            @RequestHeader("X-Correlation-Id") String correlationId
    ) {
        RequestContextValidator.requireCorrelationId(correlationId);
        return manualResolutionQueueQueryService.list(tenantId, limit);
    }

    @PostMapping("/cases/{caseId}/manual-resolution/subtype")
    @RequiresTenantRole({MembershipRole.TENANT_ADMIN, MembershipRole.COORDINATOR, MembershipRole.REGIONAL_COORD, MembershipRole.PLATFORM_ADMIN})
    public ExecutionPlanResponse resolveSubtype(
            @PathVariable Long caseId,
            @RequestParam String tenantId,
            @RequestHeader("X-Correlation-Id") String correlationId,
            @Valid @RequestBody ManualSubtypeResolutionRequest request
    ) {
        RequestContextValidator.requireCorrelationId(correlationId);
        return manualResolutionCommandService.resolveSubtype(tenantId, caseId, request);
    }

    @GetMapping("/cases/{caseId}/report-basis")
    @RequiresTenantRole({MembershipRole.TENANT_ADMIN, MembershipRole.COORDINATOR, MembershipRole.REGIONAL_COORD, MembershipRole.AUDITOR, MembershipRole.PLATFORM_ADMIN})
    public ReportBasisResponse reportBasis(
            @PathVariable Long caseId,
            @RequestParam String tenantId,
            @RequestHeader("X-Correlation-Id") String correlationId
    ) {
        RequestContextValidator.requireCorrelationId(correlationId);
        return reportBasisQueryService.get(tenantId, caseId);
    }

    @GetMapping("/analytics-readiness")
    @RequiresTenantRole({MembershipRole.TENANT_ADMIN, MembershipRole.COORDINATOR, MembershipRole.REGIONAL_COORD, MembershipRole.AUDITOR, MembershipRole.PLATFORM_ADMIN})
    public IntelligenceAnalyticsReadinessResponse analyticsReadiness(
            @RequestParam String tenantId,
            @RequestHeader("X-Correlation-Id") String correlationId
    ) {
        RequestContextValidator.requireCorrelationId(correlationId);
        return intelligenceAnalyticsReadinessQueryService.get(tenantId);
    }

    @GetMapping("/reference-profiles")
    @RequiresTenantRole({MembershipRole.TENANT_ADMIN, MembershipRole.COORDINATOR, MembershipRole.REGIONAL_COORD, MembershipRole.AUDITOR, MembershipRole.PLATFORM_ADMIN})
    public OperationalReferenceProfilesResponse referenceProfiles(
            @RequestParam String tenantId,
            @RequestHeader("X-Correlation-Id") String correlationId
    ) {
        RequestContextValidator.requireCorrelationId(correlationId);
        return operationalReferenceProfilesQueryService.list(tenantId);
    }

    @PostMapping("/reference-profiles")
    @RequiresTenantRole({MembershipRole.TENANT_ADMIN, MembershipRole.COORDINATOR, MembershipRole.REGIONAL_COORD, MembershipRole.PLATFORM_ADMIN})
    public OperationalReferenceProfilesResponse.Item createReferenceProfile(
            @RequestParam String tenantId,
            @RequestHeader("X-Correlation-Id") String correlationId,
            @Valid @RequestBody OperationalReferenceProfileMutationRequest request
    ) {
        RequestContextValidator.requireCorrelationId(correlationId);
        return operationalReferenceProfileCommandService.create(tenantId, request);
    }

    @PutMapping("/reference-profiles/{profileId}")
    @RequiresTenantRole({MembershipRole.TENANT_ADMIN, MembershipRole.COORDINATOR, MembershipRole.REGIONAL_COORD, MembershipRole.PLATFORM_ADMIN})
    public OperationalReferenceProfilesResponse.Item updateReferenceProfile(
            @PathVariable Long profileId,
            @RequestParam String tenantId,
            @RequestHeader("X-Correlation-Id") String correlationId,
            @Valid @RequestBody OperationalReferenceProfileMutationRequest request
    ) {
        RequestContextValidator.requireCorrelationId(correlationId);
        return operationalReferenceProfileCommandService.update(tenantId, profileId, request);
    }

    @PostMapping("/reference-profiles/{profileId}/activate")
    @RequiresTenantRole({MembershipRole.TENANT_ADMIN, MembershipRole.COORDINATOR, MembershipRole.REGIONAL_COORD, MembershipRole.PLATFORM_ADMIN})
    public OperationalReferenceProfilesResponse.Item activateReferenceProfile(
            @PathVariable Long profileId,
            @RequestParam String tenantId,
            @RequestHeader("X-Correlation-Id") String correlationId
    ) {
        RequestContextValidator.requireCorrelationId(correlationId);
        return operationalReferenceProfileCommandService.setActive(tenantId, profileId, true);
    }

    @PostMapping("/reference-profiles/{profileId}/deactivate")
    @RequiresTenantRole({MembershipRole.TENANT_ADMIN, MembershipRole.COORDINATOR, MembershipRole.REGIONAL_COORD, MembershipRole.PLATFORM_ADMIN})
    public OperationalReferenceProfilesResponse.Item deactivateReferenceProfile(
            @PathVariable Long profileId,
            @RequestParam String tenantId,
            @RequestHeader("X-Correlation-Id") String correlationId
    ) {
        RequestContextValidator.requireCorrelationId(correlationId);
        return operationalReferenceProfileCommandService.setActive(tenantId, profileId, false);
    }

    @PostMapping("/reference-profiles/rebuild")
    @RequiresTenantRole({MembershipRole.TENANT_ADMIN, MembershipRole.COORDINATOR, MembershipRole.REGIONAL_COORD, MembershipRole.PLATFORM_ADMIN})
    public OperationalReferenceRebuildResponse rebuildReferenceProfiles(
            @RequestParam String tenantId,
            @RequestHeader("X-Correlation-Id") String correlationId
    ) {
        RequestContextValidator.requireCorrelationId(correlationId);
        return operationalReferenceRebuildService.rebuild(tenantId);
    }

    @GetMapping("/capture-gates")
    @RequiresTenantRole({MembershipRole.TENANT_ADMIN, MembershipRole.COORDINATOR, MembershipRole.REGIONAL_COORD, MembershipRole.AUDITOR, MembershipRole.PLATFORM_ADMIN})
    public CaptureGatePolicyResponse captureGates(
            @RequestParam String tenantId,
            @RequestHeader("X-Correlation-Id") String correlationId
    ) {
        RequestContextValidator.requireCorrelationId(correlationId);
        return captureGatePolicyService.resolve(tenantId);
    }

    @GetMapping("/normative-matrix")
    @RequiresTenantRole({MembershipRole.TENANT_ADMIN, MembershipRole.COORDINATOR, MembershipRole.REGIONAL_COORD, MembershipRole.AUDITOR, MembershipRole.PLATFORM_ADMIN})
    public NormativeMatrixResponse normativeMatrix(
            @RequestParam String tenantId,
            @RequestHeader("X-Correlation-Id") String correlationId
    ) {
        RequestContextValidator.requireCorrelationId(correlationId);
        return normativeMatrixService.resolve(tenantId);
    }

    @GetMapping("/cases/{caseId}/resolve-preview")
    @RequiresTenantRole({MembershipRole.TENANT_ADMIN, MembershipRole.COORDINATOR, MembershipRole.REGIONAL_COORD, MembershipRole.AUDITOR, MembershipRole.PLATFORM_ADMIN})
    public ResolvePreviewResponse resolvePreview(
            @PathVariable Long caseId,
            @RequestParam String tenantId,
            @RequestHeader("X-Correlation-Id") String correlationId
    ) {
        RequestContextValidator.requireCorrelationId(correlationId);
        return resolvePreviewQueryService.get(tenantId, caseId);
    }
}
