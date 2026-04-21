package com.appbackoffice.api.intelligence.dto;

import java.util.List;

public record ResolvePreviewResponse(
        Long caseId,
        String caseNumber,
        String propertyAddress,
        ResolvedClassification classification,
        CaptureGatePolicyResponse captureGatePolicy,
        NormativeMatrixResponse.Profile normativeProfile,
        List<String> previewNotes
) {
    public record ResolvedClassification(
            String assetType,
            String assetSubtype,
            List<String> candidateAssetSubtypes,
            String context
    ) {
    }
}
