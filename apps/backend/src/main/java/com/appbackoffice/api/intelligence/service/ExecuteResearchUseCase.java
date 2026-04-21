package com.appbackoffice.api.intelligence.service;

import com.appbackoffice.api.intelligence.entity.CaseEnrichmentRunEntity;
import com.appbackoffice.api.intelligence.port.ResearchProvider;
import com.appbackoffice.api.intelligence.port.ResearchProviderRequest;
import com.appbackoffice.api.intelligence.port.ResearchProviderResponse;
import com.appbackoffice.api.job.entity.InspectionCase;
import org.springframework.stereotype.Service;

@Service
public class ExecuteResearchUseCase {

    private final ResearchProvider researchProvider;

    public ExecuteResearchUseCase(ResearchProvider researchProvider) {
        this.researchProvider = researchProvider;
    }

    public ResearchProviderResponse execute(InspectionCase inspectionCase, CaseEnrichmentRunEntity run) {
        ResearchProviderRequest request = new ResearchProviderRequest(
                inspectionCase.getTenantId(),
                inspectionCase.getId(),
                inspectionCase.getNumber(),
                inspectionCase.getPropertyAddress(),
                inspectionCase.getInspectionType()
        );
        return researchProvider.execute(request);
    }
}
