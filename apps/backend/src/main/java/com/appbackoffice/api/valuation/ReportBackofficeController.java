package com.appbackoffice.api.valuation;

import com.appbackoffice.api.contract.RequestContextValidator;
import com.appbackoffice.api.identity.entity.MembershipRole;
import com.appbackoffice.api.security.RequiresTenantRole;
import com.appbackoffice.api.valuation.dto.ReportDetailResponse;
import com.appbackoffice.api.valuation.dto.ReportListResponse;
import com.appbackoffice.api.valuation.dto.ReviewReportRequest;
import com.appbackoffice.api.valuation.service.ReportBackofficeService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/backoffice/reports")
public class ReportBackofficeController {

    private final ReportBackofficeService reportBackofficeService;

    public ReportBackofficeController(ReportBackofficeService reportBackofficeService) {
        this.reportBackofficeService = reportBackofficeService;
    }

    @GetMapping
    @RequiresTenantRole({MembershipRole.TENANT_ADMIN, MembershipRole.COORDINATOR, MembershipRole.REGIONAL_COORD, MembershipRole.AUDITOR, MembershipRole.PLATFORM_ADMIN})
    public ReportListResponse list(
            @RequestParam String tenantId,
            @RequestHeader("X-Correlation-Id") String correlationId,
            @RequestParam(required = false) String status
    ) {
        RequestContextValidator.requireCorrelationId(correlationId);
        return reportBackofficeService.list(tenantId, status);
    }

    @PostMapping("/{valuationProcessId}/generate")
    @RequiresTenantRole({MembershipRole.TENANT_ADMIN, MembershipRole.COORDINATOR, MembershipRole.REGIONAL_COORD, MembershipRole.PLATFORM_ADMIN})
    public ReportDetailResponse generate(
            @PathVariable Long valuationProcessId,
            @RequestParam String tenantId,
            @RequestHeader("X-Correlation-Id") String correlationId,
            @RequestHeader(value = "X-Actor-Id", required = false) String actorId
    ) {
        RequestContextValidator.requireCorrelationId(correlationId);
        return reportBackofficeService.generate(tenantId, valuationProcessId, actorId);
    }

    @GetMapping("/{reportId}")
    @RequiresTenantRole({MembershipRole.TENANT_ADMIN, MembershipRole.COORDINATOR, MembershipRole.REGIONAL_COORD, MembershipRole.AUDITOR, MembershipRole.PLATFORM_ADMIN})
    public ReportDetailResponse detail(
            @PathVariable Long reportId,
            @RequestParam String tenantId,
            @RequestHeader("X-Correlation-Id") String correlationId
    ) {
        RequestContextValidator.requireCorrelationId(correlationId);
        return reportBackofficeService.detail(tenantId, reportId);
    }

    @PostMapping("/{reportId}/review")
    @RequiresTenantRole({MembershipRole.TENANT_ADMIN, MembershipRole.COORDINATOR, MembershipRole.REGIONAL_COORD, MembershipRole.PLATFORM_ADMIN})
    public ReportDetailResponse review(
            @PathVariable Long reportId,
            @RequestParam String tenantId,
            @RequestHeader("X-Correlation-Id") String correlationId,
            @RequestHeader(value = "X-Actor-Id", required = false) String actorId,
            @RequestBody ReviewReportRequest request
    ) {
        RequestContextValidator.requireCorrelationId(correlationId);
        return reportBackofficeService.review(tenantId, reportId, request, actorId);
    }
}
