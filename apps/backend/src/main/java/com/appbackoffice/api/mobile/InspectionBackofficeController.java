package com.appbackoffice.api.mobile;

import com.appbackoffice.api.contract.RequestContextValidator;
import com.appbackoffice.api.identity.entity.MembershipRole;
import com.appbackoffice.api.mobile.dto.InspectionBackofficeDetailResponse;
import com.appbackoffice.api.mobile.dto.InspectionBackofficeListResponse;
import com.appbackoffice.api.mobile.dto.InspectionManualClassificationRequest;
import com.appbackoffice.api.mobile.service.InspectionBackofficeService;
import com.appbackoffice.api.mobile.service.InspectionManualClassificationService;
import com.appbackoffice.api.security.RequiresTenantRole;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;

@RestController
@RequestMapping("/api/backoffice/inspections")
public class InspectionBackofficeController {

    private final InspectionBackofficeService inspectionBackofficeService;
    private final InspectionManualClassificationService inspectionManualClassificationService;

    public InspectionBackofficeController(InspectionBackofficeService inspectionBackofficeService,
                                          InspectionManualClassificationService inspectionManualClassificationService) {
        this.inspectionBackofficeService = inspectionBackofficeService;
        this.inspectionManualClassificationService = inspectionManualClassificationService;
    }

    @GetMapping
    @RequiresTenantRole({MembershipRole.TENANT_ADMIN, MembershipRole.COORDINATOR, MembershipRole.AUDITOR, MembershipRole.PLATFORM_ADMIN})
    public InspectionBackofficeListResponse list(
            @RequestParam String tenantId,
            @RequestHeader("X-Correlation-Id") String correlationId,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) Instant from,
            @RequestParam(required = false) Instant to,
            @RequestParam(required = false) Long fieldAgentId,
            @RequestParam(required = false) Long vistoriadorId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size
    ) {
        RequestContextValidator.requireCorrelationId(correlationId);
        Long resolvedFieldAgentId = fieldAgentId != null ? fieldAgentId : vistoriadorId;
        return inspectionBackofficeService.list(tenantId, status, from, to, resolvedFieldAgentId, page, size);
    }

    @GetMapping("/{inspectionId}")
    @RequiresTenantRole({MembershipRole.TENANT_ADMIN, MembershipRole.COORDINATOR, MembershipRole.AUDITOR, MembershipRole.PLATFORM_ADMIN})
    public InspectionBackofficeDetailResponse detail(
            @PathVariable Long inspectionId,
            @RequestParam String tenantId,
            @RequestHeader("X-Correlation-Id") String correlationId
    ) {
        RequestContextValidator.requireCorrelationId(correlationId);
        return inspectionBackofficeService.detail(tenantId, inspectionId);
    }

    @PostMapping("/{inspectionId}/manual-classification")
    @RequiresTenantRole({MembershipRole.TENANT_ADMIN, MembershipRole.COORDINATOR, MembershipRole.AUDITOR, MembershipRole.PLATFORM_ADMIN})
    public InspectionBackofficeDetailResponse applyManualClassification(
            @PathVariable Long inspectionId,
            @RequestParam String tenantId,
            @RequestHeader("X-Correlation-Id") String correlationId,
            @RequestHeader("X-Actor-Id") String actorId,
            @Valid @RequestBody InspectionManualClassificationRequest request
    ) {
        RequestContextValidator.requireCorrelationId(correlationId);
        return inspectionManualClassificationService.apply(
                tenantId,
                inspectionId,
                Long.parseLong(actorId),
                request
        );
    }
}
