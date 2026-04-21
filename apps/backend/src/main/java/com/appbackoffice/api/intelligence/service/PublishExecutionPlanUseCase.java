package com.appbackoffice.api.intelligence.service;

import com.appbackoffice.api.intelligence.entity.ExecutionPlanSnapshotEntity;
import com.appbackoffice.api.intelligence.entity.ExecutionPlanStatus;
import com.appbackoffice.api.intelligence.model.ExecutionPlanPayload;
import com.appbackoffice.api.intelligence.repository.ExecutionPlanSnapshotRepository;
import org.springframework.stereotype.Service;

import java.time.Instant;

@Service
public class PublishExecutionPlanUseCase {

    private final ExecutionPlanSnapshotRepository snapshotRepository;
    private final ExecutionPlanPayloadMapper executionPlanPayloadMapper;

    public PublishExecutionPlanUseCase(ExecutionPlanSnapshotRepository snapshotRepository,
                                       ExecutionPlanPayloadMapper executionPlanPayloadMapper) {
        this.snapshotRepository = snapshotRepository;
        this.executionPlanPayloadMapper = executionPlanPayloadMapper;
    }

    public ExecutionPlanSnapshotEntity publish(String tenantId,
                                               Long caseId,
                                               Long sourceRunId,
                                               ExecutionPlanPayload plan,
                                               boolean requiresManualReview) {
        ExecutionPlanSnapshotEntity snapshot = new ExecutionPlanSnapshotEntity();
        snapshot.setTenantId(tenantId);
        snapshot.setCaseId(caseId);
        snapshot.setSourceRunId(sourceRunId);
        snapshot.setStatus(requiresManualReview ? ExecutionPlanStatus.REVIEW_REQUIRED : ExecutionPlanStatus.PUBLISHED);
        snapshot.setPlanJson(executionPlanPayloadMapper.write(plan));
        snapshot.setPublishedAt(Instant.now());
        return snapshotRepository.save(snapshot);
    }
}
