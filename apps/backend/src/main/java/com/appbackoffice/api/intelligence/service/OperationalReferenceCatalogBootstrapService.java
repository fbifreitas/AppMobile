package com.appbackoffice.api.intelligence.service;

import com.appbackoffice.api.intelligence.entity.OperationalReferenceProfileEntity;
import com.appbackoffice.api.intelligence.entity.OperationalReferenceScope;
import com.appbackoffice.api.intelligence.entity.OperationalReferenceSourceType;
import com.appbackoffice.api.intelligence.model.ExecutionPlanPayload;
import com.appbackoffice.api.intelligence.repository.OperationalReferenceProfileRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class OperationalReferenceCatalogBootstrapService {

    private final OperationalReferenceProfileRepository repository;
    private final OperationalReferenceProfileCodec codec;
    private final OperationalCaptureCatalog fallbackCatalog;

    public OperationalReferenceCatalogBootstrapService(OperationalReferenceProfileRepository repository,
                                                       OperationalReferenceProfileCodec codec,
                                                       OperationalCaptureCatalog fallbackCatalog) {
        this.repository = repository;
        this.codec = codec;
        this.fallbackCatalog = fallbackCatalog;
    }

    @Transactional
    public void bootstrapIfEmpty() {
        if (repository.count() > 0) {
            return;
        }

        repository.saveAll(OperationalReferenceSeedCatalog.globalSeedProfiles(fallbackCatalog).stream()
                .map(this::toEntity)
                .toList());
    }

    private OperationalReferenceProfileEntity toEntity(OperationalReferenceSeedCatalog.SeedProfile seedProfile) {
        OperationalReferenceProfileEntity entity = new OperationalReferenceProfileEntity();
        entity.setScopeType(OperationalReferenceScope.GLOBAL_REFERENCE);
        entity.setSourceType(OperationalReferenceSourceType.SEED_BOOTSTRAP);
        entity.setActiveFlag(true);
        entity.setAssetType(seedProfile.assetType());
        entity.setAssetSubtype(seedProfile.assetSubtype());
        entity.setRefinedAssetSubtype(seedProfile.refinedAssetSubtype());
        entity.setPropertyStandard(seedProfile.propertyStandard());
        entity.setPriorityWeight(seedProfile.priorityWeight());
        entity.setConfidenceScore(seedProfile.confidenceScore());
        entity.setFeedbackCount(0);
        entity.setCandidateSubtypesJson(codec.writeStringList(seedProfile.candidateSubtypes()));
        entity.setPhotoLocationsJson(codec.writeStringList(seedProfile.photoLocations()));
        entity.setCompositionJson(codec.writeComposition(seedProfile.compositionProfiles()));
        return entity;
    }
}
