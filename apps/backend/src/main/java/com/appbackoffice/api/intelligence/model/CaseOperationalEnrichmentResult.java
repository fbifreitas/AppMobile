package com.appbackoffice.api.intelligence.model;

import com.appbackoffice.api.job.entity.InspectionCase;

public record CaseOperationalEnrichmentResult(
        InspectionCase inspectionCase,
        DerivedOperationalAssetProfile assetProfile
) {
}
