package com.appbackoffice.api.intelligence.service;

import com.appbackoffice.api.contract.ApiContractException;
import com.appbackoffice.api.contract.ErrorSeverity;
import com.appbackoffice.api.intelligence.dto.ExecutionPlanResponse;
import com.appbackoffice.api.intelligence.dto.ManualSubtypeResolutionRequest;
import com.appbackoffice.api.intelligence.entity.ExecutionPlanSnapshotEntity;
import com.appbackoffice.api.intelligence.model.ExecutionPlanPayload;
import com.appbackoffice.api.intelligence.repository.ExecutionPlanSnapshotRepository;
import com.appbackoffice.api.job.entity.InspectionCase;
import com.appbackoffice.api.job.repository.CaseRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

@Service
@Transactional
public class ManualResolutionCommandService {

    private static final String MANUAL_OVERRIDE_REASON = "MANUAL_SUBTYPE_OVERRIDE_APPLIED";

    private final CaseRepository caseRepository;
    private final ExecutionPlanSnapshotRepository snapshotRepository;
    private final ExecutionPlanPayloadMapper executionPlanPayloadMapper;
    private final PublishExecutionPlanUseCase publishExecutionPlanUseCase;
    private final OperationalCaptureCatalog captureCatalog;
    private final NormativeMatrixService normativeMatrixService;
    private final NormativeCameraTreeOverlayService normativeCameraTreeOverlayService;

    public ManualResolutionCommandService(CaseRepository caseRepository,
                                          ExecutionPlanSnapshotRepository snapshotRepository,
                                          ExecutionPlanPayloadMapper executionPlanPayloadMapper,
                                          PublishExecutionPlanUseCase publishExecutionPlanUseCase,
                                          OperationalCaptureCatalog captureCatalog,
                                          NormativeMatrixService normativeMatrixService,
                                          NormativeCameraTreeOverlayService normativeCameraTreeOverlayService) {
        this.caseRepository = caseRepository;
        this.snapshotRepository = snapshotRepository;
        this.executionPlanPayloadMapper = executionPlanPayloadMapper;
        this.publishExecutionPlanUseCase = publishExecutionPlanUseCase;
        this.captureCatalog = captureCatalog;
        this.normativeMatrixService = normativeMatrixService;
        this.normativeCameraTreeOverlayService = normativeCameraTreeOverlayService;
    }

    public ExecutionPlanResponse resolveSubtype(String tenantId,
                                                Long caseId,
                                                ManualSubtypeResolutionRequest request) {
        InspectionCase inspectionCase = caseRepository.findByTenantIdAndId(tenantId, caseId)
                .orElseThrow(() -> new ApiContractException(
                        HttpStatus.NOT_FOUND,
                        "CASE_NOT_FOUND",
                        "Case not found for the informed tenant",
                        ErrorSeverity.ERROR,
                        "Provide a valid case identifier for the current tenant.",
                        "caseId=" + caseId
                ));

        ExecutionPlanSnapshotEntity latestSnapshot = snapshotRepository
                .findTopByTenantIdAndCaseIdOrderByCreatedAtDesc(tenantId, caseId)
                .orElseThrow(() -> new ApiContractException(
                        HttpStatus.NOT_FOUND,
                        "EXECUTION_PLAN_NOT_FOUND",
                        "No execution plan found for the informed case",
                        ErrorSeverity.ERROR,
                        "Trigger enrichment before applying a manual subtype resolution.",
                        "caseId=" + caseId
                ));

        ExecutionPlanPayload currentPlan = executionPlanPayloadMapper.read(latestSnapshot.getPlanJson());
        String resolvedSubtype = normalize(request.assetSubtype());
        String assetType = firstNonBlank(
                currentPlan.assetType(),
                currentPlan.propertyProfile() != null ? currentPlan.propertyProfile().canonicalAssetType() : null,
                "Urbano"
        );

        List<String> candidateSubtypes = reorderCandidates(
                resolvedSubtype,
                currentPlan.step1Config() != null ? currentPlan.step1Config().candidateAssetSubtypes() : List.of(),
                currentPlan.propertyProfile() != null ? currentPlan.propertyProfile().candidateAssetSubtypes() : List.of(),
                captureCatalog.referenceCandidateSubtypes(assetType, resolvedSubtype)
        );

        List<ExecutionPlanPayload.CameraEnvironmentProfile> compositionProfiles =
                captureCatalog.referenceCompositionProfiles(assetType, resolvedSubtype);
        List<String> availablePhotoLocations = compositionProfiles.stream()
                .map(ExecutionPlanPayload.CameraEnvironmentProfile::photoLocation)
                .distinct()
                .toList();
        String initialContext = captureCatalog.resolveInitialContext(
                assetType,
                resolvedSubtype,
                availablePhotoLocations,
                compositionProfiles
        );
        List<ExecutionPlanPayload.CapturePlanItem> capturePlan = captureCatalog.buildCapturePlan(
                compositionProfiles,
                initialContext
        );
        var normativeProfile = normativeMatrixService.resolveProfile(assetType, resolvedSubtype, resolvedSubtype);
        var overlayResult = normativeCameraTreeOverlayService.apply(
                assetType,
                resolvedSubtype,
                resolvedSubtype,
                compositionProfiles,
                capturePlan,
                normativeProfile
        );
        compositionProfiles = overlayResult.compositionProfiles();
        capturePlan = overlayResult.capturePlan();
        availablePhotoLocations = compositionProfiles.stream()
                .map(ExecutionPlanPayload.CameraEnvironmentProfile::photoLocation)
                .distinct()
                .toList();
        initialContext = captureCatalog.resolveInitialContext(
                assetType,
                resolvedSubtype,
                availablePhotoLocations,
                compositionProfiles
        );
        List<String> availableContexts = captureCatalog.resolveAvailableContexts(compositionProfiles);

        List<String> reviewReasons = new ArrayList<>();
        reviewReasons.add(MANUAL_OVERRIDE_REASON);
        if (request.note() != null && !request.note().isBlank()) {
            reviewReasons.add("MANUAL_NOTE: " + request.note().trim());
        }

        List<String> fieldAlerts = new ArrayList<>();
        if (currentPlan.fieldAlerts() != null) {
            for (String alert : currentPlan.fieldAlerts()) {
                if (alert == null || alert.isBlank()) {
                    continue;
                }
                if (alert.contains("INSUFFICIENT_STRUCTURAL_EVIDENCE_FOR_SUBTYPE") ||
                        alert.contains("CONFLICTING_SUBTYPE_SIGNALS")) {
                    continue;
                }
                fieldAlerts.add(alert);
            }
        }
        fieldAlerts.add("Manual subtype override applied by backoffice.");

        ExecutionPlanPayload nextPlan = new ExecutionPlanPayload(
                currentPlan.planVersion(),
                currentPlan.caseId(),
                currentPlan.caseNumber(),
                assetType,
                resolvedSubtype,
                currentPlan.providerName(),
                currentPlan.confidenceScore(),
                false,
                new ExecutionPlanPayload.PropertyProfile(
                        currentPlan.propertyProfile() != null ? currentPlan.propertyProfile().address() : inspectionCase.getPropertyAddress(),
                        currentPlan.propertyProfile() != null ? currentPlan.propertyProfile().latitude() : inspectionCase.getPropertyLatitude(),
                        currentPlan.propertyProfile() != null ? currentPlan.propertyProfile().longitude() : inspectionCase.getPropertyLongitude(),
                        currentPlan.propertyProfile() != null ? currentPlan.propertyProfile().taxonomy() : null,
                        currentPlan.propertyProfile() != null ? currentPlan.propertyProfile().inspectionType() : inspectionCase.getInspectionType(),
                        assetType,
                        resolvedSubtype,
                        candidateSubtypes,
                        resolvedSubtype,
                        currentPlan.propertyProfile() != null ? currentPlan.propertyProfile().propertyStandard() : null,
                        availablePhotoLocations,
                        currentPlan.propertyProfile() != null ? currentPlan.propertyProfile().structuralFacts() : null
                ),
                new ExecutionPlanPayload.Step1Config(
                        currentPlan.step1Config() != null && currentPlan.step1Config().enabled(),
                        assetType,
                        resolvedSubtype,
                        candidateSubtypes,
                        initialContext,
                        availableContexts
                ),
                currentPlan.step2Config(),
                new ExecutionPlanPayload.CameraConfig(
                        currentPlan.cameraConfig() != null ? currentPlan.cameraConfig().mode() : "guided",
                        initialContext,
                        availableContexts,
                        availablePhotoLocations,
                        capturePlan,
                        compositionProfiles
                ),
                List.copyOf(reviewReasons),
                List.copyOf(fieldAlerts),
                currentPlan.traceability()
        );

        ExecutionPlanSnapshotEntity published = publishExecutionPlanUseCase.publish(
                tenantId,
                caseId,
                latestSnapshot.getSourceRunId(),
                nextPlan,
                false
        );

        return new ExecutionPlanResponse(
                published.getId(),
                published.getCaseId(),
                published.getStatus(),
                published.getCreatedAt(),
                published.getPublishedAt(),
                nextPlan
        );
    }

    private List<String> reorderCandidates(String resolvedSubtype, List<String>... candidateGroups) {
        Set<String> ordered = new LinkedHashSet<>();
        ordered.add(resolvedSubtype);
        for (List<String> group : candidateGroups) {
            if (group == null) {
                continue;
            }
            for (String candidate : group) {
                String normalized = normalize(candidate);
                if (!normalized.isBlank()) {
                    ordered.add(normalized);
                }
            }
        }
        return List.copyOf(ordered);
    }

    private String firstNonBlank(String... values) {
        for (String value : values) {
            if (value != null && !value.isBlank()) {
                return value.trim();
            }
        }
        return "";
    }

    private String normalize(String value) {
        return value == null ? "" : value.trim();
    }
}
