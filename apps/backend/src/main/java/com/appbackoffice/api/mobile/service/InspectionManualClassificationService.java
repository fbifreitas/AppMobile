package com.appbackoffice.api.mobile.service;

import com.appbackoffice.api.intelligence.entity.ExecutionPlanSnapshotEntity;
import com.appbackoffice.api.intelligence.model.ExecutionPlanPayload;
import com.appbackoffice.api.intelligence.repository.ExecutionPlanSnapshotRepository;
import com.appbackoffice.api.intelligence.service.ExecutionPlanPayloadMapper;
import com.appbackoffice.api.intelligence.service.MobileExecutionReturnNormalizationService;
import com.appbackoffice.api.intelligence.service.StoreMobileExecutionReturnUseCase;
import com.appbackoffice.api.job.entity.Job;
import com.appbackoffice.api.job.repository.JobRepository;
import com.appbackoffice.api.mobile.dto.InspectionBackofficeDetailResponse;
import com.appbackoffice.api.mobile.dto.InspectionFinalizedRequest;
import com.appbackoffice.api.mobile.dto.InspectionManualClassificationRequest;
import com.appbackoffice.api.mobile.entity.InspectionEntity;
import com.appbackoffice.api.mobile.entity.InspectionSubmissionEntity;
import com.appbackoffice.api.mobile.repository.InspectionRepository;
import com.appbackoffice.api.mobile.repository.InspectionSubmissionRepository;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
public class InspectionManualClassificationService {

    private final InspectionRepository inspectionRepository;
    private final InspectionSubmissionRepository inspectionSubmissionRepository;
    private final InspectionBackofficeService inspectionBackofficeService;
    private final JobRepository jobRepository;
    private final ExecutionPlanSnapshotRepository executionPlanSnapshotRepository;
    private final ExecutionPlanPayloadMapper executionPlanPayloadMapper;
    private final MobileExecutionReturnNormalizationService normalizationService;
    private final StoreMobileExecutionReturnUseCase storeMobileExecutionReturnUseCase;
    private final ObjectMapper objectMapper;

    public InspectionManualClassificationService(InspectionRepository inspectionRepository,
                                                 InspectionSubmissionRepository inspectionSubmissionRepository,
                                                 InspectionBackofficeService inspectionBackofficeService,
                                                 JobRepository jobRepository,
                                                 ExecutionPlanSnapshotRepository executionPlanSnapshotRepository,
                                                 ExecutionPlanPayloadMapper executionPlanPayloadMapper,
                                                 MobileExecutionReturnNormalizationService normalizationService,
                                                 StoreMobileExecutionReturnUseCase storeMobileExecutionReturnUseCase,
                                                 ObjectMapper objectMapper) {
        this.inspectionRepository = inspectionRepository;
        this.inspectionSubmissionRepository = inspectionSubmissionRepository;
        this.inspectionBackofficeService = inspectionBackofficeService;
        this.jobRepository = jobRepository;
        this.executionPlanSnapshotRepository = executionPlanSnapshotRepository;
        this.executionPlanPayloadMapper = executionPlanPayloadMapper;
        this.normalizationService = normalizationService;
        this.storeMobileExecutionReturnUseCase = storeMobileExecutionReturnUseCase;
        this.objectMapper = objectMapper;
    }

    @Transactional
    public InspectionBackofficeDetailResponse apply(String tenantId,
                                                    Long inspectionId,
                                                    Long actorUserId,
                                                    InspectionManualClassificationRequest request) {
        InspectionEntity inspection = inspectionRepository.findByIdAndTenantId(inspectionId, tenantId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Inspection nao encontrada"));
        InspectionSubmissionEntity submission = inspectionSubmissionRepository.findById(inspection.getSubmissionId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Inspection submission nao encontrada"));

        Map<String, Object> payload = readPayload(inspection.getPayloadJson());
        if (!isFreeCapturePayload(payload)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Inspection is not awaiting manual classification");
        }

        List<Map<String, Object>> updatedCaptures = buildUpdatedCaptures(payload, request.captures());
        Map<String, Object> updatedStep2 = request.step2() == null
                ? readMap(payload.get("step2"))
                : new LinkedHashMap<>(request.step2());

        validateCaptures(updatedCaptures);
        validateStep2(payload, updatedStep2);
        validateMandatoryEvidence(tenantId, inspection, payload, updatedCaptures, updatedStep2);

        Map<String, Object> review = readMap(payload.get("review"));
        review.put("captures", updatedCaptures);
        review.put("reviewedCaptures", buildReviewedCaptures(updatedCaptures));

        payload.put("step2", updatedStep2);
        payload.put("review", review);
        payload.put("manualClassificationRequired", false);
        payload.put("manualClassificationCompletedAt", Instant.now().toString());
        payload.put("manualClassificationCompletedBy", actorUserId);

        String updatedPayloadJson = writePayload(payload);
        inspection.setPayloadJson(updatedPayloadJson);
        submission.setPayloadJson(updatedPayloadJson);
        inspectionRepository.save(inspection);
        inspectionSubmissionRepository.save(submission);

        InspectionFinalizedRequest finalizedRequest = toFinalizedRequest(payload);
        storeMobileExecutionReturnUseCase.refresh(tenantId, submission, inspection, finalizedRequest);
        return inspectionBackofficeService.detail(tenantId, inspectionId);
    }

    private void validateCaptures(List<Map<String, Object>> captures) {
        if (captures.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "At least one capture is required");
        }
        boolean hasMissing = captures.stream().anyMatch(item ->
                isBlank(asText(item.get("environment"))) ||
                        isBlank(asText(item.get("macroLocal")))
        );
        if (hasMissing) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "All captures must include area and photo location before saving"
            );
        }
    }

    private void validateStep2(Map<String, Object> payload, Map<String, Object> step2) {
        Map<String, Object> step2Config = readMap(payload.get("step2Config"));
        boolean step2Required = booleanValue(step2Config.get("visivelNoFluxo"))
                || booleanValue(step2Config.get("flowVisible"))
                || booleanValue(step2Config.get("mandatory"));
        if (!step2Required) {
            return;
        }
        if (step2 == null || step2.isEmpty()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Step 2 is required for this inspection before completing manual classification"
            );
        }
    }

    private void validateMandatoryEvidence(String tenantId,
                                           InspectionEntity inspection,
                                           Map<String, Object> payload,
                                           List<Map<String, Object>> captures,
                                           Map<String, Object> step2) {
        InspectionFinalizedRequest request = toFinalizedRequest(payload, captures, step2);
        ExecutionPlanPayload executionPlan = latestExecutionPlan(tenantId, inspection.getJobId());
        Long snapshotId = latestExecutionPlanSnapshotId(tenantId, inspection.getJobId());
        Long caseId = executionPlan == null || executionPlan.caseId() == null ? 0L : executionPlan.caseId();
        var normalization = normalizationService.normalize(
                inspection.getId(),
                inspection.getJobId(),
                caseId,
                request,
                snapshotId,
                executionPlan
        );
        boolean hasMissingRequired = normalization.evidenceCandidates().stream().anyMatch(candidate -> {
            int minPhotos = candidate.minPhotos() == null ? 0 : Math.max(candidate.minPhotos(), 0);
            int captured = candidate.capturedPhotos() == null ? 0 : Math.max(candidate.capturedPhotos(), 0);
            return (candidate.requiredFlag() || minPhotos > 0) && captured < Math.max(minPhotos, 1);
        });
        if (hasMissingRequired) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Mandatory evidence is still missing. Complete classification and required captures before saving."
            );
        }
    }

    private List<Map<String, Object>> buildUpdatedCaptures(Map<String, Object> payload,
                                                           List<InspectionManualClassificationRequest.CaptureClassification> captures) {
        Map<String, Map<String, Object>> existingByPath = new LinkedHashMap<>();
        for (Map<String, Object> capture : readCaptures(payload)) {
            String filePath = asText(capture.get("filePath"));
            if (!isBlank(filePath)) {
                existingByPath.put(filePath, new LinkedHashMap<>(capture));
            }
        }
        List<Map<String, Object>> updated = new ArrayList<>();
        for (InspectionManualClassificationRequest.CaptureClassification capture : captures) {
            Map<String, Object> base = existingByPath.getOrDefault(capture.filePath(), new LinkedHashMap<>());
            base.put("filePath", capture.filePath());
            base.put("macroLocal", capture.macroLocation());
            base.put("ambiente", capture.environmentName());
            base.put("elemento", blankToNull(capture.elementName()));
            base.put("material", blankToNull(capture.material()));
            base.put("estado", blankToNull(capture.state()));
            base.put("classificationStatus", "classified");
            updated.add(base);
        }
        return List.copyOf(updated);
    }

    private List<Map<String, Object>> buildReviewedCaptures(List<Map<String, Object>> captures) {
        List<Map<String, Object>> items = new ArrayList<>();
        for (Map<String, Object> capture : captures) {
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("filePath", asText(capture.get("filePath")));
            item.put("targetItem", asText(capture.get("ambiente")));
            item.put("targetQualifier", blankToNull(asText(capture.get("elemento"))));
            item.put("materialAttribute", blankToNull(asText(capture.get("material"))));
            item.put("conditionState", blankToNull(asText(capture.get("estado"))));
            item.put("isComplete", true);
            items.add(item);
        }
        return List.copyOf(items);
    }

    private InspectionFinalizedRequest toFinalizedRequest(Map<String, Object> payload) {
        return toFinalizedRequest(payload, readCaptures(payload), readMap(payload.get("step2")));
    }

    private InspectionFinalizedRequest toFinalizedRequest(Map<String, Object> payload,
                                                          List<Map<String, Object>> captures,
                                                          Map<String, Object> step2) {
        Map<String, Object> job = readMap(payload.get("job"));
        Map<String, Object> review = readMap(payload.get("review"));
        review.put("captures", captures);
        review.put("reviewedCaptures", buildReviewedCaptures(captures));
        return new InspectionFinalizedRequest(
                Instant.parse(asText(payload.get("exportedAt"))),
                new InspectionFinalizedRequest.JobRef(asText(job.get("id")), asText(job.get("title"))),
                readMap(payload.get("step1")),
                step2,
                readMap(payload.get("step2Config")),
                review,
                booleanValue(payload.get("freeCaptureMode")),
                booleanValue(payload.get("manualClassificationRequired"))
        );
    }

    private List<Map<String, Object>> readCaptures(Map<String, Object> payload) {
        Map<String, Object> review = readMap(payload.get("review"));
        Object rawCaptures = review.get("captures");
        if (!(rawCaptures instanceof List<?> list)) {
            return List.of();
        }
        List<Map<String, Object>> captures = new ArrayList<>();
        for (Object item : list) {
            captures.add(readMap(item));
        }
        return List.copyOf(captures);
    }

    private ExecutionPlanPayload latestExecutionPlan(String tenantId, Long jobId) {
        ExecutionPlanSnapshotEntity snapshot = latestExecutionPlanSnapshot(tenantId, jobId);
        if (snapshot == null) {
            return null;
        }
        return executionPlanPayloadMapper.read(snapshot.getPlanJson());
    }

    private Long latestExecutionPlanSnapshotId(String tenantId, Long jobId) {
        ExecutionPlanSnapshotEntity snapshot = latestExecutionPlanSnapshot(tenantId, jobId);
        return snapshot != null ? snapshot.getId() : null;
    }

    private ExecutionPlanSnapshotEntity latestExecutionPlanSnapshot(String tenantId, Long jobId) {
        Job job = jobRepository.findById(jobId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Job nao encontrado"));
        return executionPlanSnapshotRepository.findTopByTenantIdAndCaseIdOrderByCreatedAtDesc(tenantId, job.getCaseId())
                .orElse(null);
    }

    private boolean isFreeCapturePayload(Map<String, Object> payload) {
        return booleanValue(payload.get("freeCaptureMode")) || booleanValue(payload.get("manualClassificationRequired"));
    }

    private boolean booleanValue(Object value) {
        return value instanceof Boolean bool && bool;
    }

    private String writePayload(Map<String, Object> payload) {
        try {
            return objectMapper.writeValueAsString(payload);
        } catch (Exception exception) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Unable to serialize inspection payload");
        }
    }

    private Map<String, Object> readPayload(String payloadJson) {
        try {
            return objectMapper.readValue(payloadJson, new TypeReference<Map<String, Object>>() {
            });
        } catch (Exception exception) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Unable to parse inspection payload");
        }
    }

    @SuppressWarnings("unchecked")
    private Map<String, Object> readMap(Object value) {
        if (!(value instanceof Map<?, ?> map)) {
            return new LinkedHashMap<>();
        }
        Map<String, Object> normalized = new LinkedHashMap<>();
        map.forEach((key, rawValue) -> {
            if (key != null) {
                normalized.put(String.valueOf(key), rawValue);
            }
        });
        return normalized;
    }

    private String asText(Object value) {
        return value == null ? "" : String.valueOf(value).trim();
    }

    private String blankToNull(String value) {
        return isBlank(value) ? null : value.trim();
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }
}
