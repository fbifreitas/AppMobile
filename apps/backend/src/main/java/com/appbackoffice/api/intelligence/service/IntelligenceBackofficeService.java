package com.appbackoffice.api.intelligence.service;

import com.appbackoffice.api.contract.ApiContractException;
import com.appbackoffice.api.contract.ErrorSeverity;
import com.appbackoffice.api.intelligence.dto.EnrichmentRunResponse;
import com.appbackoffice.api.intelligence.dto.ExecutionPlanResponse;
import com.appbackoffice.api.intelligence.dto.TriggerEnrichmentResponse;
import com.appbackoffice.api.intelligence.entity.CaseEnrichmentRunEntity;
import com.appbackoffice.api.intelligence.entity.ExecutionPlanSnapshotEntity;
import com.appbackoffice.api.intelligence.model.CaseOperationalEnrichmentResult;
import com.appbackoffice.api.intelligence.model.ExecutionPlanPayload;
import com.appbackoffice.api.intelligence.port.ResearchProviderResponse;
import com.appbackoffice.api.intelligence.repository.CaseEnrichmentRunRepository;
import com.appbackoffice.api.job.entity.InspectionCase;
import com.appbackoffice.api.job.repository.CaseRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;

@Service
public class IntelligenceBackofficeService {

    private final CaseRepository caseRepository;
    private final CaseEnrichmentRunRepository runRepository;
    private final ExecuteResearchUseCase executeResearchUseCase;
    private final ApplyCaseOperationalEnrichmentUseCase applyCaseOperationalEnrichmentUseCase;
    private final BuildExecutionHintsUseCase buildExecutionHintsUseCase;
    private final PublishExecutionPlanUseCase publishExecutionPlanUseCase;
    private final EnrichmentArtifactStorageService enrichmentArtifactStorageService;
    private final EnrichmentRunLifecycleService enrichmentRunLifecycleService;
    private final EnrichmentRunResponseFactory enrichmentRunResponseFactory;
    private final TriggerEnrichmentResponseFactory triggerEnrichmentResponseFactory;
    private final EnrichmentDomainEventPublisher enrichmentDomainEventPublisher;
    private final ExecutionPlanQueryService executionPlanQueryService;

    public IntelligenceBackofficeService(CaseRepository caseRepository,
                                         CaseEnrichmentRunRepository runRepository,
                                         ExecuteResearchUseCase executeResearchUseCase,
                                         ApplyCaseOperationalEnrichmentUseCase applyCaseOperationalEnrichmentUseCase,
                                         BuildExecutionHintsUseCase buildExecutionHintsUseCase,
                                         PublishExecutionPlanUseCase publishExecutionPlanUseCase,
                                         EnrichmentArtifactStorageService enrichmentArtifactStorageService,
                                         EnrichmentRunLifecycleService enrichmentRunLifecycleService,
                                         EnrichmentRunResponseFactory enrichmentRunResponseFactory,
                                         TriggerEnrichmentResponseFactory triggerEnrichmentResponseFactory,
                                         EnrichmentDomainEventPublisher enrichmentDomainEventPublisher,
                                         ExecutionPlanQueryService executionPlanQueryService) {
        this.caseRepository = caseRepository;
        this.runRepository = runRepository;
        this.executeResearchUseCase = executeResearchUseCase;
        this.applyCaseOperationalEnrichmentUseCase = applyCaseOperationalEnrichmentUseCase;
        this.buildExecutionHintsUseCase = buildExecutionHintsUseCase;
        this.publishExecutionPlanUseCase = publishExecutionPlanUseCase;
        this.enrichmentArtifactStorageService = enrichmentArtifactStorageService;
        this.enrichmentRunLifecycleService = enrichmentRunLifecycleService;
        this.enrichmentRunResponseFactory = enrichmentRunResponseFactory;
        this.triggerEnrichmentResponseFactory = triggerEnrichmentResponseFactory;
        this.enrichmentDomainEventPublisher = enrichmentDomainEventPublisher;
        this.executionPlanQueryService = executionPlanQueryService;
    }

    public TriggerEnrichmentResponse triggerEnrichment(String tenantId, Long caseId, String actorId, String correlationId) {
        InspectionCase inspectionCase = loadCase(tenantId, caseId);
        CaseEnrichmentRunEntity run = enrichmentRunLifecycleService.queue(tenantId, caseId);

        try {
            run = enrichmentRunLifecycleService.markRequestStored(
                    run,
                    enrichmentArtifactStorageService.storeRequestArtifact(inspectionCase, run.getId())
            );
            ResearchProviderResponse providerResponse = executeResearchUseCase.execute(inspectionCase, run);
            EnrichmentArtifactStorageService.StoredResponseArtifacts artifacts =
                    enrichmentArtifactStorageService.storeResponseArtifacts(run, providerResponse);
            run = enrichmentRunLifecycleService.complete(run, providerResponse, artifacts);

            CaseOperationalEnrichmentResult enrichmentResult = applyCaseOperationalEnrichmentUseCase.execute(
                    inspectionCase,
                    providerResponse
            );
            inspectionCase = enrichmentResult.inspectionCase();
            ExecutionPlanPayload plan = buildExecutionHintsUseCase.execute(
                    inspectionCase,
                    enrichmentResult.assetProfile(),
                    run,
                    providerResponse
            );
            ExecutionPlanSnapshotEntity snapshot = publishExecutionPlanUseCase.publish(
                    tenantId,
                    caseId,
                    run.getId(),
                    plan,
                    plan.requiresManualReview()
            );

            enrichmentDomainEventPublisher.publishTriggered(
                    tenantId,
                    actorId,
                    correlationId,
                    caseId,
                    run.getId(),
                    snapshot.getId(),
                    plan.requiresManualReview()
            );

            return triggerEnrichmentResponseFactory.create(
                    run,
                    caseId,
                    providerResponse,
                    snapshot,
                    plan
            );
        } catch (RuntimeException exception) {
            enrichmentRunLifecycleService.fail(run, exception);
            throw exception;
        }
    }

    public EnrichmentRunResponse getLatestRun(String tenantId, Long caseId) {
        CaseEnrichmentRunEntity run = runRepository.findTopByTenantIdAndCaseIdOrderByCreatedAtDesc(tenantId, caseId)
                .orElseThrow(() -> new ApiContractException(
                        HttpStatus.NOT_FOUND,
                        "ENRICHMENT_RUN_NOT_FOUND",
                        "No enrichment run found for the informed case",
                        ErrorSeverity.ERROR,
                        "Trigger enrichment before requesting the latest run.",
                        "caseId=" + caseId
                ));
        return enrichmentRunResponseFactory.create(run);
    }

    public ExecutionPlanResponse getLatestExecutionPlan(String tenantId, Long caseId) {
        return executionPlanQueryService.getLatestExecutionPlan(tenantId, caseId);
    }

    public ExecutionPlanResponse getLatestExecutionPlanForJob(String tenantId, Long jobId) {
        return executionPlanQueryService.getLatestExecutionPlanForJob(tenantId, jobId);
    }

    private InspectionCase loadCase(String tenantId, Long caseId) {
        return caseRepository.findByTenantIdAndId(tenantId, caseId)
                .orElseThrow(() -> new ApiContractException(
                        HttpStatus.NOT_FOUND,
                        "CASE_NOT_FOUND",
                        "Case not found for the informed tenant",
                        ErrorSeverity.ERROR,
                        "Provide a valid case identifier for the current tenant.",
                        "caseId=" + caseId
                ));
    }

}
