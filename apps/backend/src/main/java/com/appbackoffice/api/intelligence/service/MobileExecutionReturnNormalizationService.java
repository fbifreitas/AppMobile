package com.appbackoffice.api.intelligence.service;

import com.appbackoffice.api.intelligence.model.ExecutionPlanPayload;
import com.appbackoffice.api.mobile.dto.InspectionFinalizedRequest;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.text.Normalizer;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

@Service
public class MobileExecutionReturnNormalizationService {

    public MobileExecutionReturnNormalization normalize(Long inspectionId,
                                                        Long jobId,
                                                        Long caseId,
                                                        InspectionFinalizedRequest request,
                                                        Long executionPlanSnapshotId,
                                                        ExecutionPlanPayload executionPlan) {
        List<Map<String, Object>> captures = extractReviewCaptures(request.review());
        int capturedPhotos = captures.size();
        MobileExecutionReturnSummary summary = new MobileExecutionReturnSummary(
                inspectionId,
                jobId,
                caseId,
                request.exportedAt(),
                executionPlanSnapshotId,
                capturedPhotos,
                request.step1().keySet().stream().sorted().toList(),
                request.step2().keySet().stream().sorted().toList(),
                request.step2Config().keySet().stream().sorted().toList(),
                request.review().keySet().stream().sorted().toList(),
                executionPlan
        );

        List<FieldEvidenceCandidate> evidence = buildEvidenceCandidates(captures, request.review(), executionPlan);
        return new MobileExecutionReturnNormalization(summary, evidence);
    }

    private List<FieldEvidenceCandidate> buildEvidenceCandidates(List<Map<String, Object>> captures,
                                                                 Map<String, Object> review,
                                                                 ExecutionPlanPayload executionPlan) {
        if (executionPlan != null &&
                executionPlan.cameraConfig() != null &&
                executionPlan.cameraConfig().capturePlan() != null &&
                !executionPlan.cameraConfig().capturePlan().isEmpty()) {
            return executionPlan.cameraConfig().capturePlan().stream()
                    .map(item -> new FieldEvidenceCandidate(
                            "camera.capture-plan",
                            item.macroLocal(),
                            item.environment(),
                            item.element(),
                            item.required(),
                            item.minPhotos(),
                            countMatchingCaptures(captures, item),
                            review
                    ))
                    .toList();
        }

        int capturedPhotos = captures.size();
        return List.of(new FieldEvidenceCandidate(
                "review.summary",
                null,
                null,
                null,
                capturedPhotos > 0,
                capturedPhotos,
                    capturedPhotos,
                    review
        ));
    }

    private List<Map<String, Object>> extractReviewCaptures(Map<String, Object> review) {
        List<Map<String, Object>> captures = extractCaptureList(review.get("captures"));
        if (!captures.isEmpty()) {
            return captures;
        }
        return extractCaptureList(review.get("capturas"));
    }

    private List<Map<String, Object>> extractCaptureList(Object value) {
        if (!(value instanceof List<?> list)) {
            return List.of();
        }
        List<Map<String, Object>> captures = new ArrayList<>();
        for (Object item : list) {
            if (item instanceof Map<?, ?> rawMap) {
                Map<String, Object> normalized = new LinkedHashMap<>();
                for (Map.Entry<?, ?> entry : rawMap.entrySet()) {
                    if (entry.getKey() == null) {
                        continue;
                    }
                    normalized.put(String.valueOf(entry.getKey()), entry.getValue());
                }
                captures.add(normalized);
            }
        }
        return List.copyOf(captures);
    }

    private int countMatchingCaptures(List<Map<String, Object>> captures, ExecutionPlanPayload.CapturePlanItem item) {
        return (int) captures.stream()
                .filter(capture -> matchesCapture(capture, item))
                .count();
    }

    private boolean matchesCapture(Map<String, Object> capture, ExecutionPlanPayload.CapturePlanItem item) {
        String captureMacro = firstNonBlank(
                capture.get("macroLocal"),
                capture.get("subjectContext"),
                capture.get("captureContext")
        );
        String captureEnvironment = firstNonBlank(
                capture.get("ambiente"),
                capture.get("environment"),
                capture.get("targetItem"),
                capture.get("targetItemLabel"),
                capture.get("targetItemBase"),
                capture.get("targetItemBaseLabel")
        );
        String captureElement = firstNonBlank(
                capture.get("elemento"),
                capture.get("element"),
                capture.get("targetQualifier"),
                capture.get("targetQualifierLabel")
        );

        boolean macroMatches = normalizedEqualsOrContains(captureMacro, item.macroLocal());
        boolean environmentMatches = normalizedEqualsOrContains(captureEnvironment, item.environment());
        boolean elementMatches = isBlank(item.element()) || normalizedEqualsOrContains(captureElement, item.element());

        return macroMatches && environmentMatches && elementMatches;
    }

    private String firstNonBlank(Object... values) {
        for (Object value : values) {
            String text = value == null ? "" : String.valueOf(value).trim();
            if (!text.isEmpty()) {
                return text;
            }
        }
        return null;
    }

    private boolean normalizedEqualsOrContains(String left, String right) {
        if (isBlank(left) || isBlank(right)) {
            return false;
        }
        String normalizedLeft = normalize(left);
        String normalizedRight = normalize(right);
        return Objects.equals(normalizedLeft, normalizedRight)
                || normalizedLeft.contains(normalizedRight)
                || normalizedRight.contains(normalizedLeft);
    }

    private boolean isBlank(String value) {
        return value == null || value.isBlank();
    }

    private String normalize(String value) {
        String normalized = Normalizer.normalize(value, Normalizer.Form.NFD)
                .replaceAll("\\p{M}", "");
        return normalized.trim().toLowerCase()
                .replace('-', ' ')
                .replace('_', ' ')
                .replaceAll("\\s+", " ");
    }

    private int extractReviewPhotoCount(Map<String, Object> review) {
        Object value = review.get("photos");
        if (value instanceof Number number) {
            return Math.max(number.intValue(), 0);
        }
        return 0;
    }

    public record MobileExecutionReturnNormalization(
            MobileExecutionReturnSummary summary,
            List<FieldEvidenceCandidate> evidenceCandidates
    ) {
    }

    public record MobileExecutionReturnSummary(
            Long inspectionId,
            Long jobId,
            Long caseId,
            Instant exportedAt,
            Long executionPlanSnapshotId,
            int reviewPhotoCount,
            List<String> step1Keys,
            List<String> step2Keys,
            List<String> step2ConfigKeys,
            List<String> reviewKeys,
            ExecutionPlanPayload executionPlan
    ) {
    }

    public record FieldEvidenceCandidate(
            String sourceSection,
            String macroLocation,
            String environmentName,
            String elementName,
            boolean requiredFlag,
            Integer minPhotos,
            Integer capturedPhotos,
            Map<String, Object> evidence
    ) {
    }
}
