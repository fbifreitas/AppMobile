package com.appbackoffice.api.job.service;

import com.appbackoffice.api.contract.ApiContractException;
import com.appbackoffice.api.contract.ErrorSeverity;
import com.appbackoffice.api.identity.service.TenantGuardService;
import com.appbackoffice.api.job.dto.CreateCaseRequest;
import com.appbackoffice.api.job.dto.CreateCaseResponse;
import com.appbackoffice.api.job.entity.InspectionCase;
import com.appbackoffice.api.job.entity.Job;
import com.appbackoffice.api.job.repository.CaseRepository;
import com.appbackoffice.api.job.repository.JobRepository;
import com.appbackoffice.api.job.repository.JobTimelineRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class CaseService {

    private final CaseRepository caseRepository;
    private final JobRepository jobRepository;
    private final JobTimelineRepository timelineRepository;
    private final TenantGuardService tenantGuardService;

    public CaseService(CaseRepository caseRepository,
                       JobRepository jobRepository,
                       JobTimelineRepository timelineRepository,
                       TenantGuardService tenantGuardService) {
        this.caseRepository = caseRepository;
        this.jobRepository = jobRepository;
        this.timelineRepository = timelineRepository;
        this.tenantGuardService = tenantGuardService;
    }

    @Transactional
    public CreateCaseResponse createCase(String tenantId, String actorId, CreateCaseRequest request) {
        tenantGuardService.requireActiveTenant(tenantId);
        String normalizedCaseNumber = request.number().trim();
        if (caseRepository.existsByTenantIdAndNumber(tenantId, normalizedCaseNumber)) {
            throw new ApiContractException(
                    HttpStatus.CONFLICT,
                    "CASE_NUMBER_ALREADY_EXISTS",
                    "Case number already exists for this tenant",
                    ErrorSeverity.ERROR,
                    "Use a unique case number within the tenant scope before creating a new job.",
                    "tenantId=" + tenantId + ", caseNumber=" + normalizedCaseNumber
            );
        }

        InspectionCase inspectionCase = new InspectionCase(
                tenantId,
                normalizedCaseNumber,
                request.propertyAddress(),
                request.propertyLatitude(),
                request.propertyLongitude(),
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
