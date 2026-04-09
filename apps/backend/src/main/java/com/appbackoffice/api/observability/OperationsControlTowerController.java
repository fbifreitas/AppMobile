package com.appbackoffice.api.observability;

import com.appbackoffice.api.contract.RequestContextValidator;
import com.appbackoffice.api.identity.entity.MembershipRole;
import com.appbackoffice.api.observability.dto.OperationsControlTowerResponse;
import com.appbackoffice.api.observability.dto.RetentionExecutionResponse;
import com.appbackoffice.api.security.RequiresTenantRole;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/backoffice/operations/control-tower")
public class OperationsControlTowerController {

    private final OperationsControlTowerService controlTowerService;
    private final OperationsRetentionService retentionService;

    public OperationsControlTowerController(OperationsControlTowerService controlTowerService,
                                           OperationsRetentionService retentionService) {
        this.controlTowerService = controlTowerService;
        this.retentionService = retentionService;
    }

    @GetMapping
    @RequiresTenantRole({MembershipRole.TENANT_ADMIN, MembershipRole.COORDINATOR, MembershipRole.AUDITOR, MembershipRole.PLATFORM_ADMIN})
    public OperationsControlTowerResponse dashboard(@RequestParam String tenantId,
                                                    @RequestHeader("X-Correlation-Id") String correlationId) {
        RequestContextValidator.requireCorrelationId(correlationId);
        return controlTowerService.getDashboard(tenantId);
    }

    @PostMapping("/retention/run")
    @RequiresTenantRole({MembershipRole.TENANT_ADMIN, MembershipRole.COORDINATOR, MembershipRole.PLATFORM_ADMIN})
    public RetentionExecutionResponse runRetention(@RequestParam String tenantId,
                                                   @RequestHeader("X-Correlation-Id") String correlationId) {
        RequestContextValidator.requireCorrelationId(correlationId);
        controlTowerService.getDashboard(tenantId);
        return retentionService.runRetentionNow();
    }
}
