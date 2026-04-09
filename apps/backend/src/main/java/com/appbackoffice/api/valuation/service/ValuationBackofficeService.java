package com.appbackoffice.api.valuation.service;

import com.appbackoffice.api.contract.ApiContractException;
import com.appbackoffice.api.contract.ErrorSeverity;
import com.appbackoffice.api.identity.service.TenantGuardService;
import com.appbackoffice.api.mobile.entity.InspectionEntity;
import com.appbackoffice.api.mobile.repository.InspectionRepository;
import com.appbackoffice.api.observability.OperationalEventRecorder;
import com.appbackoffice.api.observability.RequestTracingFilter;
import com.appbackoffice.api.valuation.dto.CreateValuationProcessRequest;
import com.appbackoffice.api.valuation.dto.ValidateIntakeRequest;
import com.appbackoffice.api.valuation.dto.ValuationProcessDetailResponse;
import com.appbackoffice.api.valuation.dto.ValuationProcessListResponse;
import com.appbackoffice.api.valuation.entity.IntakeValidationEntity;
import com.appbackoffice.api.valuation.entity.IntakeValidationResult;
import com.appbackoffice.api.valuation.entity.ValuationProcessEntity;
import com.appbackoffice.api.valuation.entity.ValuationProcessStatus;
import com.appbackoffice.api.valuation.repository.IntakeValidationRepository;
import com.appbackoffice.api.valuation.repository.ReportRepository;
import com.appbackoffice.api.valuation.repository.ValuationProcessRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.slf4j.MDC;

import java.util.List;
import java.util.LinkedHashMap;
import java.util.Map;

@Service
public class ValuationBackofficeService {

    private final ValuationProcessRepository valuationProcessRepository;
    private final IntakeValidationRepository intakeValidationRepository;
    private final ReportRepository reportRepository;
    private final InspectionRepository inspectionRepository;
    private final TenantGuardService tenantGuardService;
    private final ObjectMapper objectMapper;
    private final OperationalEventRecorder operationalEventRecorder;

    public ValuationBackofficeService(ValuationProcessRepository valuationProcessRepository,
                                      IntakeValidationRepository intakeValidationRepository,
                                      ReportRepository reportRepository,
                                      InspectionRepository inspectionRepository,
                                      TenantGuardService tenantGuardService,
                                      ObjectMapper objectMapper,
                                      OperationalEventRecorder operationalEventRecorder) {
        this.valuationProcessRepository = valuationProcessRepository;
        this.intakeValidationRepository = intakeValidationRepository;
        this.reportRepository = reportRepository;
        this.inspectionRepository = inspectionRepository;
        this.tenantGuardService = tenantGuardService;
        this.objectMapper = objectMapper;
        this.operationalEventRecorder = operationalEventRecorder;
    }

    @Transactional
    public ValuationProcessDetailResponse ensureProcessForInspection(String tenantId, Long inspectionId) {
        tenantGuardService.requireActiveTenant(tenantId);
        return toDetail(findOrCreateProcess(tenantId, requireInspectionInTenant(tenantId, inspectionId)));
    }

    @Transactional
    public ValuationProcessDetailResponse createProcess(String tenantId,
                                                        CreateValuationProcessRequest request,
                                                        String actorId) {
        tenantGuardService.requireActiveTenant(tenantId);
        InspectionEntity inspection = requireInspectionInTenant(tenantId, request.inspectionId());
        ValuationProcessEntity process = valuationProcessRepository
                .findByInspectionIdAndTenantId(inspection.getId(), tenantId)
                .orElseGet(() -> {
                    ValuationProcessEntity created = new ValuationProcessEntity();
                    created.setInspectionId(inspection.getId());
                    created.setTenantId(tenantId);
                    created.setStatus(ValuationProcessStatus.PENDING_INTAKE);
                    created.setMethod(normalizeMethod(request.method()));
                    created.setAssignedAnalystId(resolveAnalystId(request.assignedAnalystId(), actorId));
                    return valuationProcessRepository.save(created);
                });

        if (process.getAssignedAnalystId() == null) {
            process.setAssignedAnalystId(resolveAnalystId(request.assignedAnalystId(), actorId));
        }
        if (process.getMethod() == null || process.getMethod().isBlank()) {
            process.setMethod(normalizeMethod(request.method()));
        }

        return toDetail(valuationProcessRepository.save(process));
    }

    @Transactional(readOnly = true)
    public ValuationProcessListResponse list(String tenantId, String status) {
        tenantGuardService.requireActiveTenant(tenantId);
        List<ValuationProcessEntity> items = status == null || status.isBlank()
                ? valuationProcessRepository.findByTenantIdOrderByUpdatedAtDescIdDesc(tenantId)
                : valuationProcessRepository.findByTenantIdAndStatusOrderByUpdatedAtDescIdDesc(
                        tenantId,
                        parseProcessStatus(status)
                );

        return new ValuationProcessListResponse(items.size(), items.stream().map(this::toItem).toList());
    }

    @Transactional(readOnly = true)
    public ValuationProcessDetailResponse detail(String tenantId, Long processId) {
        tenantGuardService.requireActiveTenant(tenantId);
        return toDetail(requireProcessInTenant(tenantId, processId));
    }

    @Transactional
    public ValuationProcessDetailResponse validateIntake(String tenantId,
                                                         Long processId,
                                                         ValidateIntakeRequest request,
                                                         String actorId) {
        tenantGuardService.requireActiveTenant(tenantId);
        ValuationProcessEntity process = requireProcessInTenant(tenantId, processId);
        IntakeValidationResult result = parseValidationResult(request.result());

        IntakeValidationEntity validation = new IntakeValidationEntity();
        validation.setValuationProcessId(process.getId());
        validation.setValidatedBy(resolveActorUserId(actorId));
        validation.setIssuesJson(writeJson(request.issues()));
        validation.setNotes(request.notes());
        validation.setResult(result);
        intakeValidationRepository.save(validation);

        process.setStatus(result == IntakeValidationResult.VALIDATED
                ? ValuationProcessStatus.INTAKE_VALIDATED
                : ValuationProcessStatus.INTAKE_REJECTED);
        process.setAssignedAnalystId(resolveAnalystId(process.getAssignedAnalystId(), actorId));
        ValuationProcessEntity saved = valuationProcessRepository.save(process);
        Map<String, Object> details = new LinkedHashMap<>();
        details.put("result", result.name());
        details.put("valuationProcessId", saved.getId());
        details.put("assignedAnalystId", saved.getAssignedAnalystId());
        operationalEventRecorder.recordDomainEvent(
                tenantId,
                "BACKOFFICE",
                result == IntakeValidationResult.VALIDATED ? "INTAKE_VALIDATED" : "INTAKE_REJECTED",
                "backoffice.valuation.validate-intake",
                result == IntakeValidationResult.VALIDATED ? "SUCCESS" : "WARNING",
                actorId,
                MDC.get(RequestTracingFilter.CORRELATION_ID_MDC_KEY),
                MDC.get(RequestTracingFilter.TRACE_ID_MDC_KEY),
                null,
                null,
                saved.getId(),
                null,
                false,
                "Valuation intake reviewed",
                details
        );
        return toDetail(saved);
    }

    private ValuationProcessEntity findOrCreateProcess(String tenantId, InspectionEntity inspection) {
        return valuationProcessRepository.findByInspectionIdAndTenantId(inspection.getId(), tenantId)
                .orElseGet(() -> {
                    ValuationProcessEntity entity = new ValuationProcessEntity();
                    entity.setInspectionId(inspection.getId());
                    entity.setTenantId(tenantId);
                    entity.setStatus(ValuationProcessStatus.PENDING_INTAKE);
                    entity.setMethod("BASIC");
                    return valuationProcessRepository.save(entity);
                });
    }

    private InspectionEntity requireInspectionInTenant(String tenantId, Long inspectionId) {
        return inspectionRepository.findByIdAndTenantId(inspectionId, tenantId)
                .orElseThrow(() -> new ApiContractException(
                        HttpStatus.NOT_FOUND,
                        "INSPECTION_NOT_FOUND",
                        "Inspection was not found",
                        ErrorSeverity.ERROR,
                        "Provide a valid inspection identifier for the same tenant.",
                        "tenantId=" + tenantId + ", inspectionId=" + inspectionId
                ));
    }

    private ValuationProcessEntity requireProcessInTenant(String tenantId, Long processId) {
        return valuationProcessRepository.findByIdAndTenantId(processId, tenantId)
                .orElseThrow(() -> new ApiContractException(
                        HttpStatus.NOT_FOUND,
                        "VALUATION_PROCESS_NOT_FOUND",
                        "Valuation process was not found",
                        ErrorSeverity.ERROR,
                        "Provide a valid valuation process identifier for the same tenant.",
                        "tenantId=" + tenantId + ", processId=" + processId
                ));
    }

    private ValuationProcessListResponse.Item toItem(ValuationProcessEntity entity) {
        Long reportId = reportRepository.findByValuationProcessIdAndTenantId(entity.getId(), entity.getTenantId())
                .map(report -> report.getId())
                .orElse(null);
        return new ValuationProcessListResponse.Item(
                entity.getId(),
                entity.getInspectionId(),
                entity.getTenantId(),
                entity.getStatus().name(),
                entity.getMethod(),
                entity.getAssignedAnalystId(),
                reportId,
                entity.getCreatedAt(),
                entity.getUpdatedAt()
        );
    }

    private ValuationProcessDetailResponse toDetail(ValuationProcessEntity entity) {
        JsonNode issues = null;
        IntakeValidationEntity validation = intakeValidationRepository
                .findTopByValuationProcessIdOrderByValidatedAtDescIdDesc(entity.getId())
                .orElse(null);
        ValuationProcessDetailResponse.IntakeValidationSummary summary = null;
        if (validation != null) {
            issues = readJson(validation.getIssuesJson());
            summary = new ValuationProcessDetailResponse.IntakeValidationSummary(
                    validation.getResult().name(),
                    validation.getValidatedBy(),
                    validation.getValidatedAt(),
                    validation.getNotes(),
                    issues
            );
        }
        Long reportId = reportRepository.findByValuationProcessIdAndTenantId(entity.getId(), entity.getTenantId())
                .map(report -> report.getId())
                .orElse(null);

        return new ValuationProcessDetailResponse(
                entity.getId(),
                entity.getInspectionId(),
                entity.getTenantId(),
                entity.getStatus().name(),
                entity.getMethod(),
                entity.getAssignedAnalystId(),
                reportId,
                entity.getCreatedAt(),
                entity.getUpdatedAt(),
                summary
        );
    }

    private Long resolveAnalystId(Long requestedAnalystId, String actorId) {
        if (requestedAnalystId != null && requestedAnalystId > 0) {
            return requestedAnalystId;
        }
        return resolveActorUserId(actorId);
    }

    private Long resolveActorUserId(String actorId) {
        try {
            return actorId == null || actorId.isBlank() ? null : Long.parseLong(actorId);
        } catch (NumberFormatException exception) {
            return null;
        }
    }

    private String normalizeMethod(String method) {
        return method == null || method.isBlank() ? "BASIC" : method.trim().toUpperCase();
    }

    private ValuationProcessStatus parseProcessStatus(String rawStatus) {
        try {
            return ValuationProcessStatus.valueOf(rawStatus.trim().toUpperCase());
        } catch (IllegalArgumentException exception) {
            throw new ApiContractException(
                    HttpStatus.BAD_REQUEST,
                    "VALUATION_STATUS_INVALID",
                    "Valuation status is invalid",
                    ErrorSeverity.ERROR,
                    "Use one of the supported valuation process statuses.",
                    "status=" + rawStatus
            );
        }
    }

    private IntakeValidationResult parseValidationResult(String rawResult) {
        try {
            return IntakeValidationResult.valueOf(rawResult.trim().toUpperCase());
        } catch (Exception exception) {
            throw new ApiContractException(
                    HttpStatus.BAD_REQUEST,
                    "INTAKE_VALIDATION_RESULT_INVALID",
                    "Intake validation result is invalid",
                    ErrorSeverity.ERROR,
                    "Use VALIDATED or REJECTED when validating intake.",
                    "result=" + rawResult
            );
        }
    }

    private String writeJson(JsonNode node) {
        if (node == null || node.isNull()) {
            return null;
        }
        try {
            return objectMapper.writeValueAsString(node);
        } catch (Exception exception) {
            throw new ApiContractException(
                    HttpStatus.BAD_REQUEST,
                    "INTAKE_ISSUES_SERIALIZATION_FAILED",
                    "Intake issues could not be serialized",
                    ErrorSeverity.ERROR,
                    "Review the intake validation issues payload and try again.",
                    exception.getMessage()
            );
        }
    }

    private JsonNode readJson(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        try {
            return objectMapper.readTree(value);
        } catch (Exception exception) {
            throw new ApiContractException(
                    HttpStatus.INTERNAL_SERVER_ERROR,
                    "INTAKE_ISSUES_DESERIALIZATION_FAILED",
                    "Stored intake issues could not be read",
                    ErrorSeverity.ERROR,
                    "Inspect the persisted intake validation payload.",
                    exception.getMessage()
            );
        }
    }
}
