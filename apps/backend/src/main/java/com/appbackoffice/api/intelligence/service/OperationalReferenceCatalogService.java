package com.appbackoffice.api.intelligence.service;

import com.appbackoffice.api.intelligence.entity.OperationalReferenceProfileEntity;
import com.appbackoffice.api.intelligence.entity.OperationalReferenceScope;
import com.appbackoffice.api.intelligence.model.ExecutionPlanPayload;
import com.appbackoffice.api.intelligence.model.ResolvedOperationalReferenceProfile;
import com.appbackoffice.api.intelligence.port.ResearchProviderResponse;
import com.appbackoffice.api.intelligence.repository.OperationalReferenceProfileRepository;
import com.appbackoffice.api.job.entity.InspectionCase;
import org.springframework.stereotype.Service;

import java.text.Normalizer;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Optional;
import java.util.Set;

@Service
public class OperationalReferenceCatalogService {

    private final OperationalReferenceProfileRepository repository;
    private final OperationalReferenceProfileCodec codec;
    private final OperationalCaptureCatalog fallbackCatalog;
    private final ResearchFactResolver factResolver;

    public OperationalReferenceCatalogService(OperationalReferenceProfileRepository repository,
                                              OperationalReferenceProfileCodec codec,
                                              OperationalCaptureCatalog fallbackCatalog,
                                              ResearchFactResolver factResolver) {
        this.repository = repository;
        this.codec = codec;
        this.fallbackCatalog = fallbackCatalog;
        this.factResolver = factResolver;
    }

    public ResolvedOperationalReferenceProfile resolve(InspectionCase inspectionCase,
                                                       ResearchProviderResponse providerResponse,
                                                       String canonicalAssetType,
                                                       String canonicalAssetSubtype,
                                                       String refinedAssetSubtype,
                                                       String propertyStandard) {
        Optional<OperationalReferenceProfileEntity> bestMatch = repository
                .findByActiveFlagTrueOrderByPriorityWeightDescIdAsc()
                .stream()
                .filter(item -> matchesTenant(item, inspectionCase.getTenantId()))
                .filter(item -> matchesAssetType(item, canonicalAssetType))
                .filter(item -> matchesSubtype(item, canonicalAssetSubtype, refinedAssetSubtype))
                .filter(item -> matchesPropertyStandard(item, propertyStandard))
                .max((left, right) -> Integer.compare(
                        score(left, providerResponse, canonicalAssetSubtype, refinedAssetSubtype, propertyStandard),
                        score(right, providerResponse, canonicalAssetSubtype, refinedAssetSubtype, propertyStandard)
                ));

        if (bestMatch.isPresent()) {
            OperationalReferenceProfileEntity entity = bestMatch.get();
            return new ResolvedOperationalReferenceProfile(
                    entity.getScopeType().name(),
                    codec.readStringList(entity.getCandidateSubtypesJson()),
                    codec.readStringList(entity.getPhotoLocationsJson()),
                    codec.readComposition(entity.getCompositionJson())
            );
        }

        List<ExecutionPlanPayload.CameraEnvironmentProfile> fallbackComposition =
                fallbackCatalog.referenceCompositionProfiles(canonicalAssetType, canonicalAssetSubtype);
        return new ResolvedOperationalReferenceProfile(
                "CODE_FALLBACK",
                fallbackCatalog.referenceCandidateSubtypes(canonicalAssetType, canonicalAssetSubtype),
                fallbackComposition.stream().map(ExecutionPlanPayload.CameraEnvironmentProfile::photoLocation).toList(),
                fallbackComposition
        );
    }

    private boolean matchesTenant(OperationalReferenceProfileEntity entity, String tenantId) {
        return entity.getTenantId() == null || entity.getTenantId().isBlank() || entity.getTenantId().equalsIgnoreCase(tenantId);
    }

    private boolean matchesAssetType(OperationalReferenceProfileEntity entity, String canonicalAssetType) {
        return normalize(entity.getAssetType()).equals(normalize(canonicalAssetType));
    }

    private boolean matchesSubtype(OperationalReferenceProfileEntity entity,
                                   String canonicalAssetSubtype,
                                   String refinedAssetSubtype) {
        String entitySubtype = normalize(entity.getAssetSubtype());
        if (entitySubtype.equals(normalize(canonicalAssetSubtype))) {
            return true;
        }
        return entity.getRefinedAssetSubtype() != null &&
                !entity.getRefinedAssetSubtype().isBlank() &&
                normalize(entity.getRefinedAssetSubtype()).equals(normalize(refinedAssetSubtype));
    }

    private boolean matchesPropertyStandard(OperationalReferenceProfileEntity entity, String propertyStandard) {
        return entity.getPropertyStandard() == null ||
                entity.getPropertyStandard().isBlank() ||
                normalize(entity.getPropertyStandard()).equals(normalize(propertyStandard));
    }

    private int score(OperationalReferenceProfileEntity entity,
                      ResearchProviderResponse providerResponse,
                      String canonicalAssetSubtype,
                      String refinedAssetSubtype,
                      String propertyStandard) {
        int score = entity.getPriorityWeight();
        if (normalize(entity.getAssetSubtype()).equals(normalize(canonicalAssetSubtype))) {
            score += 100;
        }
        if (entity.getRefinedAssetSubtype() != null &&
                normalize(entity.getRefinedAssetSubtype()).equals(normalize(refinedAssetSubtype))) {
            score += 90;
        }
        if (entity.getPropertyStandard() != null &&
                normalize(entity.getPropertyStandard()).equals(normalize(propertyStandard))) {
            score += 60;
        }
        if (entity.getScopeType() == OperationalReferenceScope.REGIONAL_REFERENCE &&
                matchesRegion(entity, providerResponse)) {
            score += 120;
        }
        if (entity.getScopeType() == OperationalReferenceScope.HISTORICAL_REFERENCE &&
                matchesRegion(entity, providerResponse)) {
            score += 140;
        }
        return score;
    }

    private boolean matchesRegion(OperationalReferenceProfileEntity entity, ResearchProviderResponse providerResponse) {
        String city = factResolver.firstValue(providerResponse, "location_city", "city").orElse("");
        String state = factResolver.firstValue(providerResponse, "location_state", "state").orElse("");
        String district = factResolver.firstValue(providerResponse, "location_district", "district", "bairro").orElse("");
        return matchesOptional(entity.getRegionCity(), city)
                && matchesOptional(entity.getRegionState(), state)
                && matchesOptional(entity.getRegionDistrict(), district);
    }

    private boolean matchesOptional(String stored, String actual) {
        return stored == null || stored.isBlank() || normalize(stored).equals(normalize(actual));
    }

    private String normalize(String value) {
        String normalized = value == null ? "" : value.trim().toLowerCase(Locale.ROOT);
        return Normalizer.normalize(normalized, Normalizer.Form.NFD)
                .replaceAll("\\p{M}+", "");
    }
}
