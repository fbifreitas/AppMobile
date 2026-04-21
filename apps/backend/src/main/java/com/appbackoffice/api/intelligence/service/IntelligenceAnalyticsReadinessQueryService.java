package com.appbackoffice.api.intelligence.service;

import com.appbackoffice.api.intelligence.dto.IntelligenceAnalyticsReadinessResponse;
import com.appbackoffice.api.intelligence.entity.EnrichmentRunStatus;
import com.appbackoffice.api.intelligence.entity.ExecutionPlanStatus;
import com.appbackoffice.api.intelligence.repository.CaseEnrichmentRunRepository;
import com.appbackoffice.api.intelligence.repository.ExecutionPlanSnapshotRepository;
import com.appbackoffice.api.intelligence.repository.FieldEvidenceRecordRepository;
import com.appbackoffice.api.intelligence.repository.InspectionReturnArtifactRepository;
import org.springframework.stereotype.Service;

@Service
public class IntelligenceAnalyticsReadinessQueryService {

    private final CaseEnrichmentRunRepository runRepository;
    private final ExecutionPlanSnapshotRepository snapshotRepository;
    private final InspectionReturnArtifactRepository inspectionReturnArtifactRepository;
    private final FieldEvidenceRecordRepository fieldEvidenceRecordRepository;
    private final ManualResolutionQueueQueryService manualResolutionQueueQueryService;

    public IntelligenceAnalyticsReadinessQueryService(CaseEnrichmentRunRepository runRepository,
                                                      ExecutionPlanSnapshotRepository snapshotRepository,
                                                      InspectionReturnArtifactRepository inspectionReturnArtifactRepository,
                                                      FieldEvidenceRecordRepository fieldEvidenceRecordRepository,
                                                      ManualResolutionQueueQueryService manualResolutionQueueQueryService) {
        this.runRepository = runRepository;
        this.snapshotRepository = snapshotRepository;
        this.inspectionReturnArtifactRepository = inspectionReturnArtifactRepository;
        this.fieldEvidenceRecordRepository = fieldEvidenceRecordRepository;
        this.manualResolutionQueueQueryService = manualResolutionQueueQueryService;
    }

    public IntelligenceAnalyticsReadinessResponse get(String tenantId) {
        long enrichmentRuns = runRepository.countByTenantId(tenantId);
        long reviewRequiredRuns = runRepository.countByTenantIdAndStatus(tenantId, EnrichmentRunStatus.REVIEW_REQUIRED);
        long failedRuns = runRepository.countByTenantIdAndStatus(tenantId, EnrichmentRunStatus.FAILED);
        long executionPlans = snapshotRepository.countByTenantId(tenantId);
        long publishedExecutionPlans = snapshotRepository.countByTenantIdAndStatus(tenantId, ExecutionPlanStatus.PUBLISHED);
        long reviewRequiredExecutionPlans = snapshotRepository.countByTenantIdAndStatus(tenantId, ExecutionPlanStatus.REVIEW_REQUIRED);
        long inspectionReturnArtifacts = inspectionReturnArtifactRepository.countByTenantId(tenantId);
        long fieldEvidenceRecords = fieldEvidenceRecordRepository.countByTenantId(tenantId);
        long manualResolutionCases = manualResolutionQueueQueryService.list(tenantId, 50).total();
        long reportBasisCases = inspectionReturnArtifacts;

        return new IntelligenceAnalyticsReadinessResponse(
                enrichmentRuns,
                reviewRequiredRuns,
                failedRuns,
                executionPlans,
                publishedExecutionPlans,
                reviewRequiredExecutionPlans,
                inspectionReturnArtifacts,
                fieldEvidenceRecords,
                manualResolutionCases,
                reportBasisCases
        );
    }
}
