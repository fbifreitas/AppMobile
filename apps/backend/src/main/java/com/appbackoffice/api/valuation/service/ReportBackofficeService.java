package com.appbackoffice.api.valuation.service;

import com.appbackoffice.api.contract.ApiContractException;
import com.appbackoffice.api.contract.ErrorSeverity;
import com.appbackoffice.api.identity.service.TenantGuardService;
import com.appbackoffice.api.mobile.entity.InspectionEntity;
import com.appbackoffice.api.mobile.repository.InspectionRepository;
import com.appbackoffice.api.observability.OperationalEventRecorder;
import com.appbackoffice.api.observability.RequestTracingFilter;
import com.appbackoffice.api.valuation.dto.ReportDetailResponse;
import com.appbackoffice.api.valuation.dto.ReportListResponse;
import com.appbackoffice.api.valuation.dto.ReviewReportRequest;
import com.appbackoffice.api.valuation.entity.IntakeValidationEntity;
import com.appbackoffice.api.valuation.entity.ReportEntity;
import com.appbackoffice.api.valuation.entity.ReportStatus;
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

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
public class ReportBackofficeService {

    private final ReportRepository reportRepository;
    private final ValuationProcessRepository valuationProcessRepository;
    private final InspectionRepository inspectionRepository;
    private final IntakeValidationRepository intakeValidationRepository;
    private final TenantGuardService tenantGuardService;
    private final ObjectMapper objectMapper;
    private final OperationalEventRecorder operationalEventRecorder;

    public ReportBackofficeService(ReportRepository reportRepository,
                                   ValuationProcessRepository valuationProcessRepository,
                                   InspectionRepository inspectionRepository,
                                   IntakeValidationRepository intakeValidationRepository,
                                   TenantGuardService tenantGuardService,
                                   ObjectMapper objectMapper,
                                   OperationalEventRecorder operationalEventRecorder) {
        this.reportRepository = reportRepository;
        this.valuationProcessRepository = valuationProcessRepository;
        this.inspectionRepository = inspectionRepository;
        this.intakeValidationRepository = intakeValidationRepository;
        this.tenantGuardService = tenantGuardService;
        this.objectMapper = objectMapper;
        this.operationalEventRecorder = operationalEventRecorder;
    }

    @Transactional(readOnly = true)
    public ReportListResponse list(String tenantId, String status) {
        tenantGuardService.requireActiveTenant(tenantId);
        List<ReportEntity> items = status == null || status.isBlank()
                ? reportRepository.findByTenantIdOrderByUpdatedAtDescIdDesc(tenantId)
                : reportRepository.findByTenantIdAndStatusOrderByUpdatedAtDescIdDesc(tenantId, parseReportStatus(status));

        return new ReportListResponse(
                items.size(),
                items.stream().map(item -> new ReportListResponse.Item(
                        item.getId(),
                        item.getValuationProcessId(),
                        item.getTenantId(),
                        item.getStatus().name(),
                        item.getGeneratedBy(),
                        item.getApprovedBy(),
                        item.getCreatedAt(),
                        item.getUpdatedAt()
                )).toList()
        );
    }

    @Transactional
    public ReportDetailResponse generate(String tenantId, Long valuationProcessId, String actorId) {
        tenantGuardService.requireActiveTenant(tenantId);
        ValuationProcessEntity process = requireProcessInTenant(tenantId, valuationProcessId);
        if (process.getStatus() != ValuationProcessStatus.INTAKE_VALIDATED
                && process.getStatus() != ValuationProcessStatus.PROCESSING
                && process.getStatus() != ValuationProcessStatus.READY_FOR_SIGN) {
            throw new ApiContractException(
                    HttpStatus.CONFLICT,
                    "REPORT_GENERATION_REQUIRES_VALIDATED_INTAKE",
                    "Report generation requires a validated intake",
                    ErrorSeverity.ERROR,
                    "Validate intake before generating the report draft.",
                    "valuationProcessId=" + valuationProcessId + ", status=" + process.getStatus()
            );
        }

        InspectionEntity inspection = inspectionRepository.findByIdAndTenantId(process.getInspectionId(), tenantId)
                .orElseThrow(() -> new ApiContractException(
                        HttpStatus.NOT_FOUND,
                        "INSPECTION_NOT_FOUND",
                        "Inspection was not found",
                        ErrorSeverity.ERROR,
                        "Provide a valid inspection for the valuation process.",
                        "tenantId=" + tenantId + ", inspectionId=" + process.getInspectionId()
                ));
        IntakeValidationEntity validation = intakeValidationRepository
                .findTopByValuationProcessIdOrderByValidatedAtDescIdDesc(process.getId())
                .orElseThrow(() -> new ApiContractException(
                        HttpStatus.CONFLICT,
                        "INTAKE_VALIDATION_REQUIRED",
                        "A validated intake is required to generate the report",
                        ErrorSeverity.ERROR,
                        "Validate intake before generating the report.",
                        "valuationProcessId=" + process.getId()
                ));

        ReportEntity report = reportRepository.findByValuationProcessIdAndTenantId(process.getId(), tenantId)
                .orElseGet(() -> {
                    ReportEntity created = new ReportEntity();
                    created.setValuationProcessId(process.getId());
                    created.setTenantId(tenantId);
                    created.setStatus(ReportStatus.GENERATED);
                    created.setGeneratedBy(actorId);
                    created.setContentJson("{}");
                    return created;
                });

        report.setStatus(ReportStatus.GENERATED);
        report.setGeneratedBy(actorId);
        report.setContentJson(writeJson(buildReportContent(process, inspection, validation)));
        report = reportRepository.save(report);

        process.setStatus(ValuationProcessStatus.PROCESSING);
        valuationProcessRepository.save(process);
        operationalEventRecorder.recordDomainEvent(
                tenantId,
                "BACKOFFICE",
                "REPORT_GENERATED",
                "backoffice.reports.generate",
                "SUCCESS",
                actorId,
                MDC.get(RequestTracingFilter.CORRELATION_ID_MDC_KEY),
                MDC.get(RequestTracingFilter.TRACE_ID_MDC_KEY),
                inspection.getProtocolId(),
                inspection.getJobId(),
                process.getId(),
                report.getId(),
                false,
                "Report draft generated from validated intake",
                Map.of(
                        "valuationProcessId", process.getId(),
                        "reportId", report.getId(),
                        "inspectionId", inspection.getId()
                )
        );

        return toDetail(report);
    }

    @Transactional(readOnly = true)
    public ReportDetailResponse detail(String tenantId, Long reportId) {
        tenantGuardService.requireActiveTenant(tenantId);
        return toDetail(requireReportInTenant(tenantId, reportId));
    }

    @Transactional
    public ReportDetailResponse review(String tenantId, Long reportId, ReviewReportRequest request, String actorId) {
        tenantGuardService.requireActiveTenant(tenantId);
        ReportEntity report = requireReportInTenant(tenantId, reportId);
        ValuationProcessEntity process = requireProcessInTenant(tenantId, report.getValuationProcessId());
        String action = request.action() == null ? "" : request.action().trim().toUpperCase();

        switch (action) {
            case "APPROVE" -> {
                report.setStatus(ReportStatus.READY_FOR_SIGN);
                report.setApprovedBy(actorId);
                report.setReviewNotes(request.notes());
                process.setStatus(ValuationProcessStatus.READY_FOR_SIGN);
            }
            case "RETURN_FOR_CHANGES" -> {
                report.setStatus(ReportStatus.RETURNED);
                report.setReviewNotes(request.notes());
                process.setStatus(ValuationProcessStatus.PROCESSING);
            }
            default -> throw new ApiContractException(
                    HttpStatus.BAD_REQUEST,
                    "REPORT_REVIEW_ACTION_INVALID",
                    "Report review action is invalid",
                    ErrorSeverity.ERROR,
                    "Use APPROVE or RETURN_FOR_CHANGES when reviewing a report.",
                    "action=" + request.action()
            );
        }

        valuationProcessRepository.save(process);
        ReportEntity saved = reportRepository.save(report);
        operationalEventRecorder.recordDomainEvent(
                tenantId,
                "BACKOFFICE",
                "REPORT_REVIEWED",
                "backoffice.reports.review",
                "APPROVE".equals(action) ? "SUCCESS" : "WARNING",
                actorId,
                MDC.get(RequestTracingFilter.CORRELATION_ID_MDC_KEY),
                MDC.get(RequestTracingFilter.TRACE_ID_MDC_KEY),
                null,
                null,
                process.getId(),
                saved.getId(),
                false,
                "Report review action executed",
                Map.of(
                        "action", action,
                        "valuationProcessId", process.getId(),
                        "reportId", saved.getId()
                )
        );
        return toDetail(saved);
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

    private ReportEntity requireReportInTenant(String tenantId, Long reportId) {
        return reportRepository.findByIdAndTenantId(reportId, tenantId)
                .orElseThrow(() -> new ApiContractException(
                        HttpStatus.NOT_FOUND,
                        "REPORT_NOT_FOUND",
                        "Report was not found",
                        ErrorSeverity.ERROR,
                        "Provide a valid report identifier for the same tenant.",
                        "tenantId=" + tenantId + ", reportId=" + reportId
                ));
    }

    private Map<String, Object> buildReportContent(ValuationProcessEntity process,
                                                   InspectionEntity inspection,
                                                   IntakeValidationEntity validation) {
        Map<String, Object> content = new LinkedHashMap<>();
        content.put("valuationProcessId", process.getId());
        content.put("inspectionId", inspection.getId());
        content.put("jobId", inspection.getJobId());
        content.put("tenantId", process.getTenantId());
        content.put("status", process.getStatus().name());
        content.put("method", process.getMethod());
        content.put("protocolId", inspection.getProtocolId());
        content.put("submittedAt", inspection.getSubmittedAt());
        content.put("intakeResult", validation.getResult().name());
        content.put("intakeValidatedAt", validation.getValidatedAt());
        content.put("intakeIssues", readJson(validation.getIssuesJson()));
        content.put("inspectionPayload", readJson(inspection.getPayloadJson()));
        return content;
    }

    private ReportDetailResponse toDetail(ReportEntity report) {
        return new ReportDetailResponse(
                report.getId(),
                report.getValuationProcessId(),
                report.getTenantId(),
                report.getStatus().name(),
                report.getGeneratedBy(),
                report.getApprovedBy(),
                report.getReviewNotes(),
                report.getCreatedAt(),
                report.getUpdatedAt(),
                readJson(report.getContentJson())
        );
    }

    private ReportStatus parseReportStatus(String rawStatus) {
        try {
            return ReportStatus.valueOf(rawStatus.trim().toUpperCase());
        } catch (Exception exception) {
            throw new ApiContractException(
                    HttpStatus.BAD_REQUEST,
                    "REPORT_STATUS_INVALID",
                    "Report status is invalid",
                    ErrorSeverity.ERROR,
                    "Use one of the supported report statuses.",
                    "status=" + rawStatus
            );
        }
    }

    private String writeJson(Object value) {
        try {
            return objectMapper.writeValueAsString(value);
        } catch (Exception exception) {
            throw new ApiContractException(
                    HttpStatus.INTERNAL_SERVER_ERROR,
                    "REPORT_CONTENT_SERIALIZATION_FAILED",
                    "Report content could not be serialized",
                    ErrorSeverity.ERROR,
                    "Inspect the generated report payload.",
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
                    "REPORT_CONTENT_DESERIALIZATION_FAILED",
                    "Stored report content could not be read",
                    ErrorSeverity.ERROR,
                    "Inspect the persisted report payload.",
                    exception.getMessage()
            );
        }
    }
}
