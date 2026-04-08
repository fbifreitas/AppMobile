package com.appbackoffice.api.valuation;

import com.appbackoffice.api.contract.RequestContextValidator;
import com.appbackoffice.api.identity.entity.MembershipRole;
import com.appbackoffice.api.security.RequiresTenantRole;
import com.appbackoffice.api.valuation.dto.CreateValuationProcessRequest;
import com.appbackoffice.api.valuation.dto.ValidateIntakeRequest;
import com.appbackoffice.api.valuation.dto.ValuationProcessDetailResponse;
import com.appbackoffice.api.valuation.dto.ValuationProcessListResponse;
import com.appbackoffice.api.valuation.service.ValuationBackofficeService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/backoffice/valuation/processes")
public class ValuationBackofficeController {

    private final ValuationBackofficeService valuationBackofficeService;

    public ValuationBackofficeController(ValuationBackofficeService valuationBackofficeService) {
        this.valuationBackofficeService = valuationBackofficeService;
    }

    @GetMapping
    @RequiresTenantRole({MembershipRole.TENANT_ADMIN, MembershipRole.COORDINATOR, MembershipRole.REGIONAL_COORD, MembershipRole.AUDITOR, MembershipRole.PLATFORM_ADMIN})
    public ValuationProcessListResponse list(
            @RequestParam String tenantId,
            @RequestHeader("X-Correlation-Id") String correlationId,
            @RequestParam(required = false) String status
    ) {
        RequestContextValidator.requireCorrelationId(correlationId);
        return valuationBackofficeService.list(tenantId, status);
    }

    @PostMapping
    @RequiresTenantRole({MembershipRole.TENANT_ADMIN, MembershipRole.COORDINATOR, MembershipRole.REGIONAL_COORD, MembershipRole.PLATFORM_ADMIN})
    public ValuationProcessDetailResponse create(
            @RequestParam String tenantId,
            @RequestHeader("X-Correlation-Id") String correlationId,
            @RequestHeader(value = "X-Actor-Id", required = false) String actorId,
            @RequestBody CreateValuationProcessRequest request
    ) {
        RequestContextValidator.requireCorrelationId(correlationId);
        return valuationBackofficeService.createProcess(tenantId, request, actorId);
    }

    @GetMapping("/{processId}")
    @RequiresTenantRole({MembershipRole.TENANT_ADMIN, MembershipRole.COORDINATOR, MembershipRole.REGIONAL_COORD, MembershipRole.AUDITOR, MembershipRole.PLATFORM_ADMIN})
    public ValuationProcessDetailResponse detail(
            @PathVariable Long processId,
            @RequestParam String tenantId,
            @RequestHeader("X-Correlation-Id") String correlationId
    ) {
        RequestContextValidator.requireCorrelationId(correlationId);
        return valuationBackofficeService.detail(tenantId, processId);
    }

    @PostMapping("/{processId}/validate-intake")
    @RequiresTenantRole({MembershipRole.TENANT_ADMIN, MembershipRole.COORDINATOR, MembershipRole.REGIONAL_COORD, MembershipRole.PLATFORM_ADMIN})
    public ValuationProcessDetailResponse validateIntake(
            @PathVariable Long processId,
            @RequestParam String tenantId,
            @RequestHeader("X-Correlation-Id") String correlationId,
            @RequestHeader(value = "X-Actor-Id", required = false) String actorId,
            @RequestBody ValidateIntakeRequest request
    ) {
        RequestContextValidator.requireCorrelationId(correlationId);
        return valuationBackofficeService.validateIntake(tenantId, processId, request, actorId);
    }
}
