package com.appbackoffice.api.mobile.service;

import com.appbackoffice.api.contract.ApiContractException;
import com.appbackoffice.api.contract.ErrorSeverity;
import com.appbackoffice.api.job.service.JobService;
import com.appbackoffice.api.mobile.dto.InspectionFinalizedRequest;
import com.appbackoffice.api.mobile.dto.InspectionFinalizedResponse;
import com.appbackoffice.api.mobile.entity.InspectionEntity;
import com.appbackoffice.api.mobile.entity.InspectionSubmissionEntity;
import com.appbackoffice.api.mobile.repository.InspectionRepository;
import com.appbackoffice.api.mobile.repository.InspectionSubmissionRepository;
import com.appbackoffice.api.observability.OperationalEventRecorder;
import com.appbackoffice.api.observability.RequestTracingFilter;
import com.appbackoffice.api.valuation.service.ValuationBackofficeService;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.MDC;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;

@Service
public class InspectionSubmissionService {

    private static final Logger LOGGER = LoggerFactory.getLogger(InspectionSubmissionService.class);

    private final InspectionSubmissionRepository inspectionSubmissionRepository;
    private final InspectionRepository inspectionRepository;
    private final JobService jobService;
    private final ObjectMapper objectMapper;
    private final ValuationBackofficeService valuationBackofficeService;
    private final OperationalEventRecorder operationalEventRecorder;

    public InspectionSubmissionService(InspectionSubmissionRepository inspectionSubmissionRepository,
                                       InspectionRepository inspectionRepository,
                                       JobService jobService,
                                       ObjectMapper objectMapper,
                                       ValuationBackofficeService valuationBackofficeService,
                                       OperationalEventRecorder operationalEventRecorder) {
        this.inspectionSubmissionRepository = inspectionSubmissionRepository;
        this.inspectionRepository = inspectionRepository;
        this.jobService = jobService;
        this.objectMapper = objectMapper;
        this.valuationBackofficeService = valuationBackofficeService;
        this.operationalEventRecorder = operationalEventRecorder;
    }

    @Transactional
    public InspectionFinalizedResponse receive(String tenantId,
                                               Long actorUserId,
                                               String actorId,
                                               String idempotencyKey,
                                               InspectionFinalizedRequest request) {
        String normalizedIdempotencyKey = idempotencyKey.trim();
        String payloadJson = toJson(request);
        InspectionSubmissionEntity existing = inspectionSubmissionRepository
                .findByTenantIdAndIdempotencyKey(tenantId, normalizedIdempotencyKey)
                .orElse(null);

        if (existing != null) {
            ensureMatchingIdempotentPayload(existing, payloadJson, normalizedIdempotencyKey);
            InspectionEntity existingInspection = inspectionRepository
                    .findByTenantIdAndIdempotencyKey(tenantId, normalizedIdempotencyKey)
                    .orElse(null);

            if (existingInspection != null) {
                operationalEventRecorder.recordDomainEvent(
                        tenantId,
                        "MOBILE",
                        "RETRY",
                        "mobile.inspections.finalized",
                        "SUCCESS",
                        actorId,
                        MDC.get(RequestTracingFilter.CORRELATION_ID_MDC_KEY),
                        MDC.get(RequestTracingFilter.TRACE_ID_MDC_KEY),
                        existingInspection.getProtocolId(),
                        existingInspection.getJobId(),
                        existingInspection.getId(),
                        null,
                        true,
                        "Duplicate inspection submission resolved idempotently",
                        Map.of(
                                "idempotencyKey", normalizedIdempotencyKey,
                                "duplicate", true
                        )
                );
                return buildResponse(
                        existingInspection.getProtocolId(),
                        String.valueOf(existingInspection.getId()),
                        existingInspection.getProtocolId(),
                        existingInspection.getJobId(),
                        existingInspection.getSubmittedAt(),
                        existingInspection.getStatus(),
                        true
                );
            }

            return buildResponse(
                    existing.getProtocolId(),
                    String.valueOf(existing.getId()),
                    existing.getProtocolId(),
                    existing.getJobId(),
                    existing.getSubmittedAt(),
                    existing.getStatus(),
                    true
            );
        }

        Long jobId = parseJobId(request.job().id());

        InspectionSubmissionEntity entity = new InspectionSubmissionEntity();
        entity.setJobId(jobId);
        entity.setTenantId(tenantId);
        entity.setVistoriadorId(actorUserId);
        entity.setIdempotencyKey(normalizedIdempotencyKey);
        entity.setProtocolId(buildProtocolId());
        entity.setStatus("RECEIVED");
        entity.setPayloadJson(payloadJson);
        entity = inspectionSubmissionRepository.save(entity);

        InspectionEntity inspection = new InspectionEntity();
        inspection.setSubmissionId(entity.getId());
        inspection.setJobId(jobId);
        inspection.setTenantId(tenantId);
        inspection.setVistoriadorId(actorUserId);
        inspection.setIdempotencyKey(normalizedIdempotencyKey);
        inspection.setProtocolId(entity.getProtocolId());
        inspection.setStatus("SUBMITTED");
        inspection.setPayloadJson(payloadJson);
        inspection.setSubmittedAt(entity.getSubmittedAt());
        inspection = inspectionRepository.save(inspection);
        var process = valuationBackofficeService.ensureProcessForInspection(tenantId, inspection.getId());

        jobService.submitInspectionFromMobile(tenantId, jobId, actorId);

        operationalEventRecorder.recordDomainEvent(
                tenantId,
                "MOBILE",
                "INSPECTION_SUBMITTED",
                "mobile.inspections.finalized",
                "SUCCESS",
                actorId,
                MDC.get(RequestTracingFilter.CORRELATION_ID_MDC_KEY),
                MDC.get(RequestTracingFilter.TRACE_ID_MDC_KEY),
                entity.getProtocolId(),
                inspection.getJobId(),
                process.id(),
                null,
                false,
                "Inspection finalized and linked to valuation process",
                Map.of(
                        "inspectionId", inspection.getId(),
                        "submissionId", entity.getId(),
                        "jobId", inspection.getJobId(),
                        "processId", process.id()
                )
        );

        LOGGER.info("InspectionSubmitted event simulated: jobId={}, tenantId={}, protocolId={}", jobId, tenantId, entity.getProtocolId());

        return buildResponse(
                entity.getProtocolId(),
                String.valueOf(inspection.getId()),
                entity.getProtocolId(),
                inspection.getJobId(),
                entity.getSubmittedAt(),
                inspection.getStatus(),
                false
        );
    }

    private InspectionFinalizedResponse buildResponse(String protocolId,
                                                      String processId,
                                                      String processNumber,
                                                      Long jobId,
                                                      Instant receivedAt,
                                                      String status,
                                                      boolean duplicate) {
        return new InspectionFinalizedResponse(
                protocolId,
                processId,
                processNumber,
                jobId,
                receivedAt,
                status,
                duplicate
        );
    }

    private void ensureMatchingIdempotentPayload(InspectionSubmissionEntity existing,
                                                 String currentPayloadJson,
                                                 String idempotencyKey) {
        try {
            if (objectMapper.readTree(existing.getPayloadJson()).equals(objectMapper.readTree(currentPayloadJson))) {
                return;
            }
        } catch (JsonProcessingException exception) {
            throw new ApiContractException(
                    HttpStatus.CONFLICT,
                    "IDEMPOTENCY_KEY_PAYLOAD_MISMATCH",
                    "Idempotency key cannot be reused with a different payload",
                    ErrorSeverity.ERROR,
                    "Generate a new X-Idempotency-Key for each distinct inspection submission payload.",
                    "idempotencyKey=" + idempotencyKey
            );
        }

        throw new ApiContractException(
                HttpStatus.CONFLICT,
                "IDEMPOTENCY_KEY_PAYLOAD_MISMATCH",
                "Idempotency key cannot be reused with a different payload",
                ErrorSeverity.ERROR,
                "Generate a new X-Idempotency-Key for each distinct inspection submission payload.",
                "idempotencyKey=" + idempotencyKey
        );
    }

    private Long parseJobId(String rawJobId) {
        try {
            return Long.parseLong(rawJobId);
        } catch (NumberFormatException exception) {
            throw new ApiContractException(
                    HttpStatus.BAD_REQUEST,
                    "INVALID_JOB_ID",
                    "job.id deve ser numérico para submissão real",
                    ErrorSeverity.ERROR,
                    "Informe o identificador interno do job retornado pelo backend.",
                    "job.id=" + rawJobId
            );
        }
    }

    private String buildProtocolId() {
        return "INS-" + Instant.now().toEpochMilli() + "-" + UUID.randomUUID().toString().substring(0, 8);
    }

    private String toJson(InspectionFinalizedRequest request) {
        try {
            return objectMapper.writeValueAsString(request);
        } catch (JsonProcessingException exception) {
            throw new ApiContractException(
                    HttpStatus.BAD_REQUEST,
                    "INSPECTION_PAYLOAD_SERIALIZATION_FAILED",
                    "Falha ao serializar payload final da inspeção",
                    ErrorSeverity.ERROR,
                    "Revise o payload enviado e tente novamente.",
                    exception.getMessage()
            );
        }
    }
}
