package com.appbackoffice.api.intelligence.service;

import com.appbackoffice.api.intelligence.dto.ManualResolutionQueueResponse;
import com.appbackoffice.api.intelligence.entity.CaseEnrichmentRunEntity;
import com.appbackoffice.api.intelligence.entity.EnrichmentRunStatus;
import com.appbackoffice.api.intelligence.entity.ExecutionPlanSnapshotEntity;
import com.appbackoffice.api.intelligence.entity.ExecutionPlanStatus;
import com.appbackoffice.api.intelligence.repository.CaseEnrichmentRunRepository;
import com.appbackoffice.api.intelligence.repository.ExecutionPlanSnapshotRepository;
import com.appbackoffice.api.job.entity.InspectionCase;
import com.appbackoffice.api.job.entity.Job;
import com.appbackoffice.api.job.repository.CaseRepository;
import com.appbackoffice.api.job.repository.JobRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
@Transactional(readOnly = true)
public class ManualResolutionQueueQueryService {

    private final CaseEnrichmentRunRepository runRepository;
    private final ExecutionPlanSnapshotRepository snapshotRepository;
    private final CaseRepository caseRepository;
    private final JobRepository jobRepository;
    private final EnrichmentRunLifecycleService enrichmentRunLifecycleService;

    public ManualResolutionQueueQueryService(CaseEnrichmentRunRepository runRepository,
                                             ExecutionPlanSnapshotRepository snapshotRepository,
                                             CaseRepository caseRepository,
                                             JobRepository jobRepository,
                                             EnrichmentRunLifecycleService enrichmentRunLifecycleService) {
        this.runRepository = runRepository;
        this.snapshotRepository = snapshotRepository;
        this.caseRepository = caseRepository;
        this.jobRepository = jobRepository;
        this.enrichmentRunLifecycleService = enrichmentRunLifecycleService;
    }

    public ManualResolutionQueueResponse list(String tenantId, int limit) {
        int normalizedLimit = Math.max(1, Math.min(limit, 50));
        Map<Long, CaseEnrichmentRunEntity> latestRunByCase = latestRunByCase(tenantId);

        if (latestRunByCase.isEmpty()) {
            return new ManualResolutionQueueResponse(0, List.of());
        }

        Map<Long, InspectionCase> casesById = caseRepository.findByTenantIdAndIdIn(tenantId, latestRunByCase.keySet()).stream()
                .collect(Collectors.toMap(InspectionCase::getId, Function.identity()));

        List<ManualResolutionQueueResponse.Item> allItems = latestRunByCase.values().stream()
                .map(run -> toItem(tenantId, run, casesById.get(run.getCaseId())))
                .filter(Objects::nonNull)
                .toList();

        List<ManualResolutionQueueResponse.Item> items = allItems.stream()
                .limit(normalizedLimit)
                .toList();

        return new ManualResolutionQueueResponse(allItems.size(), items);
    }

    private Map<Long, CaseEnrichmentRunEntity> latestRunByCase(String tenantId) {
        Map<Long, CaseEnrichmentRunEntity> latestByCase = new LinkedHashMap<>();
        for (CaseEnrichmentRunEntity run : runRepository.findTop100ByTenantIdOrderByCreatedAtDesc(tenantId)) {
            latestByCase.putIfAbsent(run.getCaseId(), run);
        }
        return latestByCase;
    }

    private ManualResolutionQueueResponse.Item toItem(String tenantId,
                                                      CaseEnrichmentRunEntity run,
                                                      InspectionCase inspectionCase) {
        if (inspectionCase == null) {
            return null;
        }

        ExecutionPlanSnapshotEntity snapshot = snapshotRepository
                .findTopByTenantIdAndCaseIdOrderByCreatedAtDesc(tenantId, run.getCaseId())
                .orElse(null);
        Job latestJob = jobRepository.findTopByTenantIdAndCaseIdOrderByCreatedAtDesc(tenantId, run.getCaseId())
                .orElse(null);

        List<String> pendingReasons = resolvePendingReasons(run, snapshot);
        if (pendingReasons.isEmpty()) {
            return null;
        }

        return new ManualResolutionQueueResponse.Item(
                inspectionCase.getId(),
                inspectionCase.getNumber(),
                inspectionCase.getStatus(),
                inspectionCase.getPropertyAddress(),
                run.getId(),
                run.getStatus(),
                enrichmentRunLifecycleService.isRetryable(run),
                runRepository.countByTenantIdAndCaseId(tenantId, run.getCaseId()),
                run.getConfidenceScore(),
                run.getErrorCode(),
                run.getErrorMessage(),
                snapshot != null ? snapshot.getId() : null,
                snapshot != null ? snapshot.getStatus() : null,
                latestJob != null ? latestJob.getId() : null,
                latestJob != null ? latestJob.getStatus() : null,
                pendingReasons,
                run.getCreatedAt()
        );
    }

    private List<String> resolvePendingReasons(CaseEnrichmentRunEntity run, ExecutionPlanSnapshotEntity snapshot) {
        if (snapshot != null &&
                snapshot.getStatus() == ExecutionPlanStatus.PUBLISHED &&
                snapshot.getCreatedAt() != null &&
                run.getCreatedAt() != null &&
                snapshot.getCreatedAt().isAfter(run.getCreatedAt())) {
            return List.of();
        }

        List<String> reasons = new ArrayList<>();

        if (run.getStatus() == EnrichmentRunStatus.REVIEW_REQUIRED) {
            reasons.add("ENRICHMENT_REVIEW_REQUIRED");
        }
        if (run.getStatus() == EnrichmentRunStatus.TEMPORARILY_UNAVAILABLE) {
            reasons.add("ENRICHMENT_TEMPORARILY_UNAVAILABLE");
        }
        if (run.getStatus() == EnrichmentRunStatus.FAILED) {
            reasons.add("ENRICHMENT_FAILED");
        }
        if (snapshot == null) {
            reasons.add("EXECUTION_PLAN_MISSING");
        } else if (snapshot.getStatus() == ExecutionPlanStatus.REVIEW_REQUIRED) {
            reasons.add("EXECUTION_PLAN_REVIEW_REQUIRED");
        }

        return reasons;
    }
}
