package com.appbackoffice.api.intelligence.service;

import com.appbackoffice.api.intelligence.entity.ExecutionPlanSnapshotEntity;
import com.appbackoffice.api.intelligence.entity.FieldEvidenceRecordEntity;
import com.appbackoffice.api.intelligence.entity.FieldEvidenceStatus;
import com.appbackoffice.api.intelligence.entity.InspectionReturnArtifactEntity;
import com.appbackoffice.api.intelligence.model.ExecutionPlanPayload;
import com.appbackoffice.api.intelligence.repository.ExecutionPlanSnapshotRepository;
import com.appbackoffice.api.intelligence.repository.FieldEvidenceRecordRepository;
import com.appbackoffice.api.intelligence.repository.InspectionReturnArtifactRepository;
import com.appbackoffice.api.job.entity.Job;
import com.appbackoffice.api.job.repository.JobRepository;
import com.appbackoffice.api.mobile.dto.InspectionFinalizedRequest;
import com.appbackoffice.api.mobile.entity.InspectionEntity;
import com.appbackoffice.api.mobile.entity.InspectionSubmissionEntity;
import com.appbackoffice.api.storage.StorageResult;
import com.appbackoffice.api.storage.StorageService;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.MDC;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets;

import static com.appbackoffice.api.observability.RequestTracingFilter.CORRELATION_ID_MDC_KEY;
import static com.appbackoffice.api.observability.RequestTracingFilter.TRACE_ID_MDC_KEY;

@Service
public class StoreMobileExecutionReturnUseCase {

    private final JobRepository jobRepository;
    private final ExecutionPlanSnapshotRepository executionPlanSnapshotRepository;
    private final InspectionReturnArtifactRepository inspectionReturnArtifactRepository;
    private final FieldEvidenceRecordRepository fieldEvidenceRecordRepository;
    private final StorageService storageService;
    private final ObjectMapper objectMapper;
    private final ExecutionPlanPayloadMapper executionPlanPayloadMapper;
    private final MobileExecutionReturnNormalizationService normalizationService;
    private final MobileExecutionReturnDomainEventPublisher domainEventPublisher;

    public StoreMobileExecutionReturnUseCase(JobRepository jobRepository,
                                             ExecutionPlanSnapshotRepository executionPlanSnapshotRepository,
                                             InspectionReturnArtifactRepository inspectionReturnArtifactRepository,
                                             FieldEvidenceRecordRepository fieldEvidenceRecordRepository,
                                             StorageService storageService,
                                             ObjectMapper objectMapper,
                                             ExecutionPlanPayloadMapper executionPlanPayloadMapper,
                                             MobileExecutionReturnNormalizationService normalizationService,
                                             MobileExecutionReturnDomainEventPublisher domainEventPublisher) {
        this.jobRepository = jobRepository;
        this.executionPlanSnapshotRepository = executionPlanSnapshotRepository;
        this.inspectionReturnArtifactRepository = inspectionReturnArtifactRepository;
        this.fieldEvidenceRecordRepository = fieldEvidenceRecordRepository;
        this.storageService = storageService;
        this.objectMapper = objectMapper;
        this.executionPlanPayloadMapper = executionPlanPayloadMapper;
        this.normalizationService = normalizationService;
        this.domainEventPublisher = domainEventPublisher;
    }

    public Long store(String tenantId,
                      InspectionSubmissionEntity submission,
                      InspectionEntity inspection,
                      InspectionFinalizedRequest request) {
        return storeArtifacts(tenantId, submission, inspection, request, true);
    }

    public Long refresh(String tenantId,
                        InspectionSubmissionEntity submission,
                        InspectionEntity inspection,
                        InspectionFinalizedRequest request) {
        return storeArtifacts(tenantId, submission, inspection, request, false);
    }

    private Long storeArtifacts(String tenantId,
                                InspectionSubmissionEntity submission,
                                InspectionEntity inspection,
                                InspectionFinalizedRequest request,
                                boolean publishDomainEvent) {
        Job job = jobRepository.findById(inspection.getJobId()).orElseThrow();
        Long caseId = job.getCaseId();
        ExecutionPlanSnapshotEntity latestSnapshot = executionPlanSnapshotRepository
                .findTopByTenantIdAndCaseIdOrderByCreatedAtDesc(tenantId, caseId)
                .orElse(null);
        ExecutionPlanPayload executionPlan = latestSnapshot == null
                ? null
                : executionPlanPayloadMapper.read(latestSnapshot.getPlanJson());

        String rawJson = writeJson(objectMapper.valueToTree(request));
        MobileExecutionReturnNormalizationService.MobileExecutionReturnNormalization normalization =
                normalizationService.normalize(
                        inspection.getId(),
                        inspection.getJobId(),
                        caseId,
                        request,
                        latestSnapshot != null ? latestSnapshot.getId() : null,
                        executionPlan
                );
        String normalizedJson = writeJson(objectMapper.valueToTree(normalization.summary()));

        StorageResult rawArtifact = storageService.store(
                "raw/cases/%s/inspection-return/inspection-%s/payload.json".formatted(caseId, inspection.getId()),
                rawJson.getBytes(StandardCharsets.UTF_8),
                "application/json"
        );
        StorageResult normalizedArtifact = storageService.store(
                "normalized/cases/%s/inspection/inspection-%s/summary.json".formatted(caseId, inspection.getId()),
                normalizedJson.getBytes(StandardCharsets.UTF_8),
                "application/json"
        );

        InspectionReturnArtifactEntity artifactEntity = new InspectionReturnArtifactEntity();
        artifactEntity.setInspectionId(inspection.getId());
        artifactEntity.setSubmissionId(submission.getId());
        artifactEntity.setTenantId(tenantId);
        artifactEntity.setCaseId(caseId);
        artifactEntity.setJobId(inspection.getJobId());
        artifactEntity.setExecutionPlanSnapshotId(latestSnapshot != null ? latestSnapshot.getId() : null);
        artifactEntity.setRawStorageKey(rawArtifact.key());
        artifactEntity.setNormalizedStorageKey(normalizedArtifact.key());
        artifactEntity.setSummaryJson(normalizedJson);
        inspectionReturnArtifactRepository.save(artifactEntity);

        fieldEvidenceRecordRepository.deleteByInspectionId(inspection.getId());
        var evidenceRecords = normalization.evidenceCandidates().stream()
                .map(candidate -> buildEvidenceRecord(
                        tenantId,
                        caseId,
                        inspection,
                        candidate
                ))
                .toList();
        fieldEvidenceRecordRepository.saveAll(evidenceRecords);

        if (publishDomainEvent) {
            domainEventPublisher.publishStored(
                    tenantId,
                    String.valueOf(inspection.getFieldAgentId()),
                    MDC.get(CORRELATION_ID_MDC_KEY),
                    MDC.get(TRACE_ID_MDC_KEY),
                    inspection.getProtocolId(),
                    inspection.getId(),
                    submission.getId(),
                    caseId,
                    inspection.getJobId(),
                    latestSnapshot != null ? latestSnapshot.getId() : null,
                    evidenceRecords.size()
            );
        }

        return caseId;
    }

    private FieldEvidenceRecordEntity buildEvidenceRecord(String tenantId,
                                                          Long caseId,
                                                          InspectionEntity inspection,
                                                          MobileExecutionReturnNormalizationService.FieldEvidenceCandidate candidate) {
        FieldEvidenceRecordEntity entity = new FieldEvidenceRecordEntity();
        entity.setInspectionId(inspection.getId());
        entity.setTenantId(tenantId);
        entity.setCaseId(caseId);
        entity.setJobId(inspection.getJobId());
        entity.setSourceSection(candidate.sourceSection());
        entity.setMacroLocation(blankToNull(candidate.macroLocation()));
        entity.setEnvironmentName(blankToNull(candidate.environmentName()));
        entity.setElementName(blankToNull(candidate.elementName()));
        entity.setRequiredFlag(candidate.requiredFlag());
        entity.setMinPhotos(candidate.minPhotos());
        entity.setCapturedPhotos(candidate.capturedPhotos());
        entity.setEvidenceStatus(resolveEvidenceStatus(candidate.requiredFlag(), candidate.minPhotos(), candidate.capturedPhotos()));
        entity.setEvidenceJson(writeJson(objectMapper.valueToTree(candidate.evidence())));
        return entity;
    }

    private FieldEvidenceStatus resolveEvidenceStatus(boolean requiredFlag, Integer minPhotos, Integer capturedPhotos) {
        int safeMinimum = minPhotos == null ? 0 : Math.max(minPhotos, 0);
        int safeCaptured = capturedPhotos == null ? 0 : Math.max(capturedPhotos, 0);
        if (safeCaptured >= safeMinimum && safeCaptured > 0) {
            return FieldEvidenceStatus.COLLECTED;
        }
        if (requiredFlag || safeMinimum > 0) {
            return FieldEvidenceStatus.REVIEW_REQUIRED;
        }
        return FieldEvidenceStatus.PLANNED;
    }

    private String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value;
    }

    private String writeJson(JsonNode value) {
        try {
            return objectMapper.writeValueAsString(value);
        } catch (JsonProcessingException exception) {
            throw new IllegalStateException("Unable to serialize JSON payload", exception);
        }
    }
}
