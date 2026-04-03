package com.appbackoffice.api.job.service;

import com.appbackoffice.api.job.dto.CreateCaseRequest;
import com.appbackoffice.api.job.dto.CreateCaseResponse;
import com.appbackoffice.api.job.entity.InspectionCase;
import com.appbackoffice.api.job.entity.Job;
import com.appbackoffice.api.job.repository.CaseRepository;
import com.appbackoffice.api.job.repository.JobRepository;
import com.appbackoffice.api.job.repository.JobTimelineRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class CaseService {

    private final CaseRepository caseRepository;
    private final JobRepository jobRepository;
    private final JobTimelineRepository timelineRepository;

    public CaseService(CaseRepository caseRepository,
                       JobRepository jobRepository,
                       JobTimelineRepository timelineRepository) {
        this.caseRepository = caseRepository;
        this.jobRepository = jobRepository;
        this.timelineRepository = timelineRepository;
    }

    @Transactional
    public CreateCaseResponse createCase(String tenantId, String actorId, CreateCaseRequest request) {
        InspectionCase inspectionCase = new InspectionCase(
                tenantId,
                request.number(),
                request.propertyAddress(),
                request.inspectionType(),
                request.deadline()
        );
        InspectionCase savedCase = caseRepository.save(inspectionCase);

        // Job is created in ELIGIBLE_FOR_DISPATCH state immediately (skipping CREATED)
        Job job = new Job(savedCase.getId(), tenantId, request.jobTitle(), request.deadline());
        Job savedJob = jobRepository.save(job);

        return new CreateCaseResponse(
                savedCase.getId(),
                savedCase.getNumber(),
                savedJob.getId(),
                savedJob.getStatus().name(),
                savedCase.getCreatedAt()
        );
    }
}
