package com.appbackoffice.api.job;

import com.appbackoffice.api.contract.RequestContextValidator;
import com.appbackoffice.api.job.dto.CreateCaseRequest;
import com.appbackoffice.api.job.dto.CreateCaseResponse;
import com.appbackoffice.api.job.service.CaseService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@Validated
@RequestMapping("/cases")
@Tag(name = "Cases", description = "Gerenciamento de casos de vistoria")
public class CaseController {

    private final CaseService caseService;

    public CaseController(CaseService caseService) {
        this.caseService = caseService;
    }

    @PostMapping
    @Operation(summary = "Cria um novo case com job inicial em ELIGIBLE_FOR_DISPATCH")
    public ResponseEntity<CreateCaseResponse> createCase(
            @RequestHeader("X-Tenant-Id") String tenantId,
            @RequestHeader("X-Correlation-Id") String correlationId,
            @RequestHeader("X-Actor-Id") String actorId,
            @Valid @RequestBody CreateCaseRequest request
    ) {
        RequestContextValidator.requireFullContext(tenantId, correlationId, actorId);
        CreateCaseResponse response = caseService.createCase(tenantId, actorId, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }
}
