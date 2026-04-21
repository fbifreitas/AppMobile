package com.appbackoffice.api.intelligence.service;

import com.appbackoffice.api.intelligence.model.CaseOperationalEnrichmentResult;
import com.appbackoffice.api.intelligence.model.DerivedOperationalAssetProfile;
import com.appbackoffice.api.intelligence.port.ResearchProviderResponse;
import com.appbackoffice.api.job.entity.InspectionCase;
import com.appbackoffice.api.job.repository.CaseRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ApplyCaseOperationalEnrichmentUseCase {

    private final OperationalAssetProfileDerivationService operationalAssetProfileDerivationService;
    private final CaseGeolocationReconciliationService geolocationReconciliationService;
    private final CaseRepository caseRepository;

    public ApplyCaseOperationalEnrichmentUseCase(OperationalAssetProfileDerivationService operationalAssetProfileDerivationService,
                                                 CaseGeolocationReconciliationService geolocationReconciliationService,
                                                 CaseRepository caseRepository) {
        this.operationalAssetProfileDerivationService = operationalAssetProfileDerivationService;
        this.geolocationReconciliationService = geolocationReconciliationService;
        this.caseRepository = caseRepository;
    }

    @Transactional
    public CaseOperationalEnrichmentResult execute(InspectionCase inspectionCase,
                                                   ResearchProviderResponse providerResponse) {
        DerivedOperationalAssetProfile profile = operationalAssetProfileDerivationService
                .derive(inspectionCase, providerResponse);
        CaseGeolocationReconciliationService.ResolvedCoordinates coordinates =
                geolocationReconciliationService.resolve(inspectionCase, providerResponse);

        boolean changed = false;
        if (coordinates.latitude() != null && !coordinates.latitude().equals(inspectionCase.getPropertyLatitude())) {
            inspectionCase.setPropertyLatitude(coordinates.latitude());
            changed = true;
        }
        if (coordinates.longitude() != null && !coordinates.longitude().equals(inspectionCase.getPropertyLongitude())) {
            inspectionCase.setPropertyLongitude(coordinates.longitude());
            changed = true;
        }

        InspectionCase resolvedCase = changed ? caseRepository.save(inspectionCase) : inspectionCase;
        return new CaseOperationalEnrichmentResult(resolvedCase, profile);
    }
}
