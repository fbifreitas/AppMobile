package com.appbackoffice.api.intelligence.service;

import com.appbackoffice.api.contract.ApiContractException;
import com.appbackoffice.api.contract.ErrorSeverity;
import com.appbackoffice.api.intelligence.dto.OperationalReferenceProfilesResponse;
import com.appbackoffice.api.intelligence.entity.OperationalReferenceProfileEntity;
import com.appbackoffice.api.intelligence.entity.OperationalReferenceProfileMutationRequest;
import com.appbackoffice.api.intelligence.entity.OperationalReferenceSourceType;
import com.appbackoffice.api.intelligence.model.ExecutionPlanPayload;
import com.appbackoffice.api.intelligence.repository.OperationalReferenceProfileRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

@Service
public class OperationalReferenceProfileCommandService {

    private final OperationalReferenceProfileRepository repository;
    private final OperationalReferenceProfileCodec codec;
    private final OperationalReferenceProfilesQueryService queryService;
    private final OperationalCaptureCatalog captureCatalog;
    private final OperationalReferenceCompositionSupport compositionSupport;

    public OperationalReferenceProfileCommandService(OperationalReferenceProfileRepository repository,
                                                    OperationalReferenceProfileCodec codec,
                                                    OperationalReferenceProfilesQueryService queryService,
                                                    OperationalCaptureCatalog captureCatalog,
                                                    OperationalReferenceCompositionSupport compositionSupport) {
        this.repository = repository;
        this.codec = codec;
        this.queryService = queryService;
        this.captureCatalog = captureCatalog;
        this.compositionSupport = compositionSupport;
    }

    @Transactional
    public OperationalReferenceProfilesResponse.Item create(String tenantId, OperationalReferenceProfileMutationRequest request) {
        OperationalReferenceProfileEntity entity = new OperationalReferenceProfileEntity();
        applyMutation(entity, tenantId, request);
        repository.save(entity);
        return queryService.list(tenantId).items().stream()
                .filter(item -> item.id().equals(entity.getId()))
                .findFirst()
                .orElseThrow();
    }

    @Transactional
    public OperationalReferenceProfilesResponse.Item update(String tenantId,
                                                            Long profileId,
                                                            OperationalReferenceProfileMutationRequest request) {
        OperationalReferenceProfileEntity entity = requireEditableProfile(tenantId, profileId);
        applyMutation(entity, tenantId, request);
        repository.save(entity);
        return queryService.list(tenantId).items().stream()
                .filter(item -> item.id().equals(entity.getId()))
                .findFirst()
                .orElseThrow();
    }

    @Transactional
    public OperationalReferenceProfilesResponse.Item setActive(String tenantId, Long profileId, boolean active) {
        OperationalReferenceProfileEntity entity = requireEditableProfile(tenantId, profileId);
        entity.setActiveFlag(active);
        repository.save(entity);
        return queryService.list(tenantId).items().stream()
                .filter(item -> item.id().equals(entity.getId()))
                .findFirst()
                .orElseThrow();
    }

    private OperationalReferenceProfileEntity requireEditableProfile(String tenantId, Long profileId) {
        OperationalReferenceProfileEntity entity = repository.findById(profileId)
                .orElseThrow(() -> new ApiContractException(
                        HttpStatus.NOT_FOUND,
                        "REFERENCE_PROFILE_NOT_FOUND",
                        "Reference profile not found",
                        ErrorSeverity.ERROR,
                        "Refresh the workspace and try again.",
                        "profileId=" + profileId
                ));
        if (entity.getTenantId() == null || entity.getTenantId().isBlank() || !entity.getTenantId().equalsIgnoreCase(tenantId)) {
            throw new ApiContractException(
                    HttpStatus.FORBIDDEN,
                    "REFERENCE_PROFILE_NOT_EDITABLE",
                    "Only tenant-scoped reference profiles can be edited from the backoffice",
                    ErrorSeverity.ERROR,
                    "Create a tenant-scoped override instead of editing a global reference profile.",
                    "profileId=" + profileId
            );
        }
        return entity;
    }

    private void applyMutation(OperationalReferenceProfileEntity entity,
                               String tenantId,
                               OperationalReferenceProfileMutationRequest request) {
        String assetType = request.assetType().trim();
        String assetSubtype = request.assetSubtype().trim();
        String refinedAssetSubtype = blankToNull(request.refinedAssetSubtype());
        List<String> candidateSubtypes = sanitizeValues(request.candidateSubtypes());
        if (candidateSubtypes.isEmpty()) {
            candidateSubtypes = captureCatalog.referenceCandidateSubtypes(assetType, assetSubtype);
        }
        List<String> photoLocations = sanitizeValues(request.photoLocations());
        if (photoLocations.isEmpty()) {
            photoLocations = OperationalReferenceSeedCatalog.referencePhotoLocations(
                    captureCatalog,
                    assetType,
                    assetSubtype,
                    refinedAssetSubtype
            );
        }
        List<ExecutionPlanPayload.CameraEnvironmentProfile> composition = OperationalReferenceSeedCatalog
                .referenceCompositionProfiles(captureCatalog, assetType, assetSubtype, refinedAssetSubtype);
        composition = compositionSupport.filterByPhotoLocations(composition, photoLocations);
        if (composition.isEmpty()) {
            composition = captureCatalog.buildCompositionProfiles(assetType, assetSubtype, photoLocations);
        }

        entity.setTenantId(tenantId);
        entity.setScopeType(request.scopeType());
        entity.setSourceType(OperationalReferenceSourceType.MANUAL_CURATION);
        entity.setActiveFlag(request.activeFlag());
        entity.setAssetType(assetType);
        entity.setAssetSubtype(assetSubtype);
        entity.setRefinedAssetSubtype(refinedAssetSubtype);
        entity.setPropertyStandard(blankToNull(request.propertyStandard()));
        entity.setRegionState(blankToNull(request.regionState()));
        entity.setRegionCity(blankToNull(request.regionCity()));
        entity.setRegionDistrict(blankToNull(request.regionDistrict()));
        entity.setPriorityWeight(request.priorityWeight() == null ? 140 : request.priorityWeight());
        entity.setConfidenceScore(request.confidenceScore() == null ? 0.92d : request.confidenceScore());
        entity.setCandidateSubtypesJson(codec.writeStringList(candidateSubtypes));
        entity.setPhotoLocationsJson(codec.writeStringList(photoLocations));
        entity.setCompositionJson(codec.writeComposition(composition));
    }

    private List<String> sanitizeValues(List<String> values) {
        if (values == null) {
            return List.of();
        }
        Set<String> unique = new LinkedHashSet<>();
        for (String item : values) {
            if (item != null && !item.isBlank()) {
                unique.add(item.trim());
            }
        }
        return List.copyOf(unique);
    }

    private String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
