package com.appbackoffice.api.intelligence.service;

import com.appbackoffice.api.contract.ApiContractException;
import com.appbackoffice.api.contract.ErrorSeverity;
import com.appbackoffice.api.intelligence.dto.ExecutionPlanResponse;
import com.appbackoffice.api.intelligence.dto.ReportBasisResponse;
import com.appbackoffice.api.intelligence.entity.CaseEnrichmentRunEntity;
import com.appbackoffice.api.intelligence.entity.FieldEvidenceRecordEntity;
import com.appbackoffice.api.intelligence.entity.InspectionReturnArtifactEntity;
import com.appbackoffice.api.intelligence.repository.CaseEnrichmentRunRepository;
import com.appbackoffice.api.intelligence.repository.FieldEvidenceRecordRepository;
import com.appbackoffice.api.intelligence.repository.InspectionReturnArtifactRepository;
import com.appbackoffice.api.job.entity.InspectionCase;
import com.appbackoffice.api.job.entity.Job;
import com.appbackoffice.api.job.repository.CaseRepository;
import com.appbackoffice.api.job.repository.JobRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Transactional(readOnly = true)
public class ReportBasisQueryService {

    private final CaseRepository caseRepository;
    private final CaseEnrichmentRunRepository runRepository;
    private final ExecutionPlanQueryService executionPlanQueryService;
    private final JobRepository jobRepository;
    private final InspectionReturnArtifactRepository inspectionReturnArtifactRepository;
    private final FieldEvidenceRecordRepository fieldEvidenceRecordRepository;
    private final IntelligenceJsonPayloadMapper jsonPayloadMapper;
    private final EnrichmentRunLifecycleService enrichmentRunLifecycleService;

    public ReportBasisQueryService(CaseRepository caseRepository,
                                   CaseEnrichmentRunRepository runRepository,
                                   ExecutionPlanQueryService executionPlanQueryService,
                                   JobRepository jobRepository,
                                   InspectionReturnArtifactRepository inspectionReturnArtifactRepository,
                                   FieldEvidenceRecordRepository fieldEvidenceRecordRepository,
                                   IntelligenceJsonPayloadMapper jsonPayloadMapper,
                                   EnrichmentRunLifecycleService enrichmentRunLifecycleService) {
        this.caseRepository = caseRepository;
        this.runRepository = runRepository;
        this.executionPlanQueryService = executionPlanQueryService;
        this.jobRepository = jobRepository;
        this.inspectionReturnArtifactRepository = inspectionReturnArtifactRepository;
        this.fieldEvidenceRecordRepository = fieldEvidenceRecordRepository;
        this.jsonPayloadMapper = jsonPayloadMapper;
        this.enrichmentRunLifecycleService = enrichmentRunLifecycleService;
    }

    public ReportBasisResponse get(String tenantId, Long caseId) {
        InspectionCase inspectionCase = caseRepository.findByTenantIdAndId(tenantId, caseId)
                .orElseThrow(() -> new ApiContractException(
                        HttpStatus.NOT_FOUND,
                        "CASE_NOT_FOUND",
                        "Case not found for the informed tenant",
                        ErrorSeverity.ERROR,
                        "Provide a valid case identifier for the current tenant.",
                        "caseId=" + caseId
                ));

        CaseEnrichmentRunEntity latestRun = runRepository.findTopByTenantIdAndCaseIdOrderByCreatedAtDesc(tenantId, caseId)
                .orElse(null);
        ExecutionPlanResponse latestExecutionPlan = executionPlanQueryService.getLatestExecutionPlanOrNull(tenantId, caseId);
        Job latestJob = jobRepository.findTopByTenantIdAndCaseIdOrderByCreatedAtDesc(tenantId, caseId).orElse(null);
        InspectionReturnArtifactEntity latestReturnArtifact = inspectionReturnArtifactRepository
                .findTopByTenantIdAndCaseIdOrderByCreatedAtDesc(tenantId, caseId)
                .orElse(null);
        List<FieldEvidenceRecordEntity> fieldEvidence = fieldEvidenceRecordRepository
                .findByTenantIdAndCaseIdOrderByCreatedAtAsc(tenantId, caseId);

        return new ReportBasisResponse(
                inspectionCase.getId(),
                inspectionCase.getNumber(),
                inspectionCase.getStatus(),
                inspectionCase.getPropertyAddress(),
                toLatestRun(latestRun),
                toLatestExecutionPlan(latestExecutionPlan),
                toLatestJob(latestJob),
                toLatestReturnArtifact(latestReturnArtifact),
                fieldEvidence.stream().map(this::toFieldEvidence).toList()
        );
    }

    private ReportBasisResponse.LatestRun toLatestRun(CaseEnrichmentRunEntity run) {
        if (run == null) {
            return null;
        }
        return new ReportBasisResponse.LatestRun(
                run.getId(),
                run.getStatus(),
                enrichmentRunLifecycleService.isRetryable(run),
                runRepository.countByTenantIdAndCaseId(run.getTenantId(), run.getCaseId()),
                run.getConfidenceScore(),
                run.getCreatedAt(),
                run.getCompletedAt(),
                jsonPayloadMapper.read(run.getFactsJson()),
                jsonPayloadMapper.read(run.getQualityFlagsJson()),
                run.getErrorCode(),
                run.getErrorMessage()
        );
    }

    private ReportBasisResponse.LatestExecutionPlan toLatestExecutionPlan(ExecutionPlanResponse response) {
        if (response == null) {
            return null;
        }
        return new ReportBasisResponse.LatestExecutionPlan(
                response.snapshotId(),
                response.status(),
                response.createdAt(),
                response.publishedAt(),
                response.plan()
        );
    }

    private ReportBasisResponse.LatestJob toLatestJob(Job job) {
        if (job == null) {
            return null;
        }
        return new ReportBasisResponse.LatestJob(
                job.getId(),
                job.getStatus(),
                job.getAssignedTo(),
                job.getDeadlineAt(),
                job.getCreatedAt()
        );
    }

    private ReportBasisResponse.LatestReturnArtifact toLatestReturnArtifact(InspectionReturnArtifactEntity entity) {
        if (entity == null) {
            return null;
        }
        return new ReportBasisResponse.LatestReturnArtifact(
                entity.getInspectionId(),
                entity.getSubmissionId(),
                entity.getJobId(),
                entity.getExecutionPlanSnapshotId(),
                entity.getRawStorageKey(),
                entity.getNormalizedStorageKey(),
                jsonPayloadMapper.read(entity.getSummaryJson()),
                entity.getCreatedAt()
        );
    }

    private ReportBasisResponse.FieldEvidence toFieldEvidence(FieldEvidenceRecordEntity entity) {
        return new ReportBasisResponse.FieldEvidence(
                entity.getInspectionId(),
                entity.getJobId(),
                entity.getSourceSection(),
                entity.getMacroLocation(),
                entity.getEnvironmentName(),
                entity.getElementName(),
                entity.isRequiredFlag(),
                entity.getMinPhotos(),
                entity.getCapturedPhotos(),
                entity.getEvidenceStatus().name(),
                jsonPayloadMapper.read(entity.getEvidenceJson()),
                entity.getCreatedAt()
        );
    }
}
