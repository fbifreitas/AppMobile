package com.appbackoffice.api.intelligence.service;

import com.appbackoffice.api.intelligence.entity.CaseEnrichmentRunEntity;
import com.appbackoffice.api.intelligence.port.ResearchProvider;
import com.appbackoffice.api.intelligence.port.ResearchProviderRequest;
import com.appbackoffice.api.intelligence.port.ResearchProviderResponse;
import com.appbackoffice.api.job.entity.InspectionCase;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.stereotype.Service;

@Service
public class ExecuteResearchUseCase {

    private final ObjectProvider<ResearchProvider> researchProviderProvider;
    private final DisabledResearchProvider disabledResearchProvider = new DisabledResearchProvider();

    public ExecuteResearchUseCase(ObjectProvider<ResearchProvider> researchProviderProvider) {
        this.researchProviderProvider = researchProviderProvider;
    }

    public ResearchProviderResponse execute(InspectionCase inspectionCase, CaseEnrichmentRunEntity run) {
        ResearchProviderRequest request = new ResearchProviderRequest(
                inspectionCase.getTenantId(),
                inspectionCase.getId(),
                inspectionCase.getNumber(),
                inspectionCase.getPropertyAddress(),
                inspectionCase.getInspectionType()
        );
        return researchProviderProvider
                .getIfAvailable(() -> disabledResearchProvider)
                .execute(request);
    }
}
