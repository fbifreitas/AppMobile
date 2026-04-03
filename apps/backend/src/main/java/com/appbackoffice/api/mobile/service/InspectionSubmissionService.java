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
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.UUID;

@Service
public class InspectionSubmissionService {

    private static final Logger LOGGER = LoggerFactory.getLogger(InspectionSubmissionService.class);

    private final InspectionSubmissionRepository inspectionSubmissionRepository;
    private final InspectionRepository inspectionRepository;
    private final JobService jobService;
    private final ObjectMapper objectMapper;

    public InspectionSubmissionService(InspectionSubmissionRepository inspectionSubmissionRepository,
                                       InspectionRepository inspectionRepository,
                                       JobService jobService,
                                       ObjectMapper objectMapper) {
        this.inspectionSubmissionRepository = inspectionSubmissionRepository;
        this.inspectionRepository = inspectionRepository;
        this.jobService = jobService;
        this.objectMapper = objectMapper;
    }

    @Transactional
    public InspectionFinalizedResponse receive(String tenantId,
                                               Long actorUserId,
                                               String actorId,
                                               String idempotencyKey,
                                               InspectionFinalizedRequest request) {
        InspectionSubmissionEntity existing = inspectionSubmissionRepository
                .findByTenantIdAndIdempotencyKey(tenantId, idempotencyKey)
                .orElse(null);

        if (existing != null) {
            InspectionEntity existingInspection = inspectionRepository
                    .findByTenantIdAndIdempotencyKey(tenantId, idempotencyKey)
                    .orElse(null);

            if (existingInspection != null) {
                return new InspectionFinalizedResponse(
                        existingInspection.getProtocolId(),
                        existingInspection.getSubmittedAt(),
                        existingInspection.getStatus(),
                        true
                );
            }

            return new InspectionFinalizedResponse(existing.getProtocolId(), existing.getSubmittedAt(), existing.getStatus(), true);
        }

        Long jobId = parseJobId(request.job().id());
        String payloadJson = toJson(request);

        InspectionSubmissionEntity entity = new InspectionSubmissionEntity();
        entity.setJobId(jobId);
        entity.setTenantId(tenantId);
        entity.setVistoriadorId(actorUserId);
        entity.setIdempotencyKey(idempotencyKey.trim());
        entity.setProtocolId(buildProtocolId());
        entity.setStatus("RECEIVED");
        entity.setPayloadJson(payloadJson);
        entity = inspectionSubmissionRepository.save(entity);

        InspectionEntity inspection = new InspectionEntity();
        inspection.setSubmissionId(entity.getId());
        inspection.setJobId(jobId);
        inspection.setTenantId(tenantId);
        inspection.setVistoriadorId(actorUserId);
        inspection.setIdempotencyKey(idempotencyKey.trim());
        inspection.setProtocolId(entity.getProtocolId());
        inspection.setStatus("SUBMITTED");
        inspection.setPayloadJson(payloadJson);
        inspection.setSubmittedAt(entity.getSubmittedAt());
        inspectionRepository.save(inspection);

        jobService.submitInspectionFromMobile(tenantId, jobId, actorId);

        LOGGER.info("InspectionSubmitted event simulated: jobId={}, tenantId={}, protocolId={}", jobId, tenantId, entity.getProtocolId());

        return new InspectionFinalizedResponse(entity.getProtocolId(), entity.getSubmittedAt(), inspection.getStatus(), false);
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
