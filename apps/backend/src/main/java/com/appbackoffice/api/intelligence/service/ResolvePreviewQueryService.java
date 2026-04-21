package com.appbackoffice.api.intelligence.service;

import com.appbackoffice.api.intelligence.dto.CaptureGatePolicyResponse;
import com.appbackoffice.api.intelligence.dto.NormativeMatrixResponse;
import com.appbackoffice.api.intelligence.dto.ResolvePreviewResponse;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;

@Service
@Transactional(readOnly = true)
public class ResolvePreviewQueryService {

    private final ReportBasisQueryService reportBasisQueryService;
    private final CaptureGatePolicyService captureGatePolicyService;
    private final NormativeMatrixService normativeMatrixService;

    public ResolvePreviewQueryService(ReportBasisQueryService reportBasisQueryService,
                                      CaptureGatePolicyService captureGatePolicyService,
                                      NormativeMatrixService normativeMatrixService) {
        this.reportBasisQueryService = reportBasisQueryService;
        this.captureGatePolicyService = captureGatePolicyService;
        this.normativeMatrixService = normativeMatrixService;
    }

    public ResolvePreviewResponse get(String tenantId, Long caseId) {
        var reportBasis = reportBasisQueryService.get(tenantId, caseId);
        String assetType = "Urbano";
        String assetSubtype = "Imovel";
        List<String> candidates = List.of();
        String context = null;

        if (reportBasis.latestExecutionPlan() != null && reportBasis.latestExecutionPlan().plan() != null) {
            var plan = reportBasis.latestExecutionPlan().plan();
            assetType = firstNonBlank(plan.assetType(), assetType);
            assetSubtype = firstNonBlank(plan.assetSubtype(), assetSubtype);
            if (plan.step1Config() != null) {
                assetType = firstNonBlank(plan.step1Config().initialAssetType(), assetType);
                assetSubtype = firstNonBlank(plan.step1Config().initialAssetSubtype(), assetSubtype);
                candidates = plan.step1Config().candidateAssetSubtypes() != null
                        ? plan.step1Config().candidateAssetSubtypes()
                        : List.of();
                context = plan.step1Config().initialContext();
            }
            if (plan.propertyProfile() != null) {
                assetType = firstNonBlank(plan.propertyProfile().canonicalAssetType(), assetType);
                assetSubtype = firstNonBlank(
                        plan.propertyProfile().canonicalAssetSubtype(),
                        assetSubtype
                );
            }
        }

        CaptureGatePolicyResponse gatePolicy = captureGatePolicyService.resolve(tenantId);
        NormativeMatrixResponse.Profile normativeProfile = normativeMatrixService.resolveProfile(
                assetType,
                assetSubtype,
                reportBasis.latestExecutionPlan() != null
                        && reportBasis.latestExecutionPlan().plan() != null
                        && reportBasis.latestExecutionPlan().plan().propertyProfile() != null
                        ? reportBasis.latestExecutionPlan().plan().propertyProfile().refinedAssetSubtype()
                        : null
        );

        List<String> notes = new ArrayList<>();
        notes.add("Resolve preview combines static capture gates with the normative matrix that will be enforced at finalization.");
        if (reportBasis.latestExecutionPlan() == null) {
            notes.add("No execution plan found for this case. Preview is using static defaults.");
        }
        if (reportBasis.latestRun() != null && reportBasis.latestRun().retryable()) {
            notes.add("Latest enrichment run is retryable; review preview together with the current error state before dispatch.");
        }

        return new ResolvePreviewResponse(
                reportBasis.caseId(),
                reportBasis.caseNumber(),
                reportBasis.propertyAddress(),
                new ResolvePreviewResponse.ResolvedClassification(
                        assetType,
                        assetSubtype,
                        candidates,
                        context
                ),
                gatePolicy,
                normativeProfile,
                notes
        );
    }

    private String firstNonBlank(String preferred, String fallback) {
        return preferred != null && !preferred.isBlank() ? preferred : fallback;
    }
}
