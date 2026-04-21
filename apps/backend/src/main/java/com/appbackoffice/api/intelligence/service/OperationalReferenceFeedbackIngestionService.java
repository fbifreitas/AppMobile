package com.appbackoffice.api.intelligence.service;

import com.appbackoffice.api.intelligence.entity.OperationalReferenceProfileEntity;
import com.appbackoffice.api.intelligence.entity.OperationalReferenceScope;
import com.appbackoffice.api.intelligence.entity.OperationalReferenceSourceType;
import com.appbackoffice.api.intelligence.model.ExecutionPlanPayload;
import com.appbackoffice.api.intelligence.repository.OperationalReferenceProfileRepository;
import com.appbackoffice.api.job.entity.InspectionCase;
import com.appbackoffice.api.job.repository.CaseRepository;
import com.appbackoffice.api.mobile.dto.InspectionFinalizedRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.text.Normalizer;
import java.util.ArrayList;
import java.util.Collection;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.Set;

@Service
public class OperationalReferenceFeedbackIngestionService {

    private final CaseRepository caseRepository;
    private final OperationalReferenceProfileRepository repository;
    private final OperationalReferenceProfileCodec codec;
    private final OperationalCaptureCatalog captureCatalog;
    private final OperationalReferenceCompositionSupport compositionSupport;
    private final OperationalReferenceRegionResolver regionResolver;

    public OperationalReferenceFeedbackIngestionService(CaseRepository caseRepository,
                                                        OperationalReferenceProfileRepository repository,
                                                        OperationalReferenceProfileCodec codec,
                                                        OperationalCaptureCatalog captureCatalog,
                                                        OperationalReferenceCompositionSupport compositionSupport,
                                                        OperationalReferenceRegionResolver regionResolver) {
        this.caseRepository = caseRepository;
        this.repository = repository;
        this.codec = codec;
        this.captureCatalog = captureCatalog;
        this.compositionSupport = compositionSupport;
        this.regionResolver = regionResolver;
    }

    @Transactional
    public void ingest(String tenantId, Long caseId, InspectionFinalizedRequest request) {
        if (caseId == null) {
            return;
        }
        InspectionCase inspectionCase = caseRepository.findByTenantIdAndId(tenantId, caseId).orElse(null);
        if (inspectionCase == null) {
            return;
        }

        String assetType = readText(request.step1(), "assetType", "tipoImovel", "inspectionType");
        String assetSubtype = readText(request.step1(), "assetSubtype", "subtipoImovel");
        if (isBlank(assetType) || isBlank(assetSubtype)) {
            return;
        }

        String refinedAssetSubtype = readText(request.step1(), "refinedAssetSubtype");
        String propertyStandard = readText(request.step1(), "propertyStandard", "padraoImovel");
        List<String> candidateSubtypes = readStringList(request.step1().get("candidateAssetSubtypes"));
        if (candidateSubtypes.isEmpty()) {
            candidateSubtypes = captureCatalog.referenceCandidateSubtypes(assetType, assetSubtype);
        }

        List<Map<String, Object>> reviewedCaptures = extractMapList(request.review().get("reviewedCaptures"));
        List<String> observedPhotoLocations = sanitizeValues(reviewedCaptures.stream()
                .map(this::readPhotoLocation)
                .filter(Objects::nonNull)
                .toList());
        if (observedPhotoLocations.isEmpty()) {
            observedPhotoLocations = OperationalReferenceSeedCatalog.referencePhotoLocations(
                    captureCatalog,
                    assetType,
                    assetSubtype,
                    refinedAssetSubtype
            );
        }

        List<ExecutionPlanPayload.CameraEnvironmentProfile> baseComposition =
                OperationalReferenceSeedCatalog.referenceCompositionProfiles(
                        captureCatalog,
                        assetType,
                        assetSubtype,
                        refinedAssetSubtype
                );
        baseComposition = compositionSupport.filterByPhotoLocations(baseComposition, observedPhotoLocations);
        if (baseComposition.isEmpty()) {
            baseComposition = captureCatalog.buildCompositionProfiles(assetType, assetSubtype, observedPhotoLocations);
        }
        List<ExecutionPlanPayload.CameraEnvironmentProfile> observedComposition = buildObservedComposition(reviewedCaptures);
        List<ExecutionPlanPayload.CameraEnvironmentProfile> mergedComposition =
                compositionSupport.mergeProfiles(baseComposition, observedComposition);

        upsertProfile(
                tenantId,
                OperationalReferenceScope.HISTORICAL_REFERENCE,
                inspectionCase,
                assetType,
                assetSubtype,
                refinedAssetSubtype,
                propertyStandard,
                candidateSubtypes,
                observedPhotoLocations,
                mergedComposition
        );
        upsertProfile(
                tenantId,
                OperationalReferenceScope.REGIONAL_REFERENCE,
                inspectionCase,
                assetType,
                assetSubtype,
                refinedAssetSubtype,
                propertyStandard,
                candidateSubtypes,
                observedPhotoLocations,
                mergedComposition
        );
    }

    private void upsertProfile(String tenantId,
                               OperationalReferenceScope scopeType,
                               InspectionCase inspectionCase,
                               String assetType,
                               String assetSubtype,
                               String refinedAssetSubtype,
                               String propertyStandard,
                               List<String> candidateSubtypes,
                               List<String> photoLocations,
                               List<ExecutionPlanPayload.CameraEnvironmentProfile> composition) {
        OperationalReferenceRegionResolver.Region region = regionResolver.resolve(inspectionCase);
        Optional<OperationalReferenceProfileEntity> existing = repository.findAllByOrderByPriorityWeightDescIdAsc().stream()
                .filter(item -> tenantId.equalsIgnoreCase(item.getTenantId()))
                .filter(item -> item.getScopeType() == scopeType)
                .filter(item -> normalize(item.getAssetType()).equals(normalize(assetType)))
                .filter(item -> normalize(item.getAssetSubtype()).equals(normalize(assetSubtype)))
                .filter(item -> normalize(item.getRefinedAssetSubtype()).equals(normalize(refinedAssetSubtype)))
                .filter(item -> normalize(item.getPropertyStandard()).equals(normalize(propertyStandard)))
                .filter(item -> scopeType != OperationalReferenceScope.REGIONAL_REFERENCE || (
                        normalize(item.getRegionState()).equals(normalize(region.state()))
                                && normalize(item.getRegionCity()).equals(normalize(region.city()))
                                && normalize(item.getRegionDistrict()).equals(normalize(region.district()))
                ))
                .findFirst();

        OperationalReferenceProfileEntity entity = existing.orElseGet(OperationalReferenceProfileEntity::new);
        int nextFeedbackCount = entity.getFeedbackCount() + 1;
        List<String> mergedCandidates = mergeValues(codec.readStringList(entity.getCandidateSubtypesJson()), candidateSubtypes);
        List<String> mergedPhotoLocations = mergeValues(codec.readStringList(entity.getPhotoLocationsJson()), photoLocations);
        List<ExecutionPlanPayload.CameraEnvironmentProfile> mergedComposition =
                compositionSupport.mergeProfiles(codec.readComposition(entity.getCompositionJson()), composition);

        entity.setTenantId(tenantId);
        entity.setScopeType(scopeType);
        entity.setSourceType(OperationalReferenceSourceType.FIELD_FEEDBACK);
        entity.setActiveFlag(true);
        entity.setAssetType(assetType);
        entity.setAssetSubtype(assetSubtype);
        entity.setRefinedAssetSubtype(blankToNull(refinedAssetSubtype));
        entity.setPropertyStandard(blankToNull(propertyStandard));
        entity.setRegionState(scopeType == OperationalReferenceScope.REGIONAL_REFERENCE ? blankToNull(region.state()) : null);
        entity.setRegionCity(scopeType == OperationalReferenceScope.REGIONAL_REFERENCE ? blankToNull(region.city()) : null);
        entity.setRegionDistrict(scopeType == OperationalReferenceScope.REGIONAL_REFERENCE ? blankToNull(region.district()) : null);
        entity.setFeedbackCount(nextFeedbackCount);
        entity.setPriorityWeight((scopeType == OperationalReferenceScope.REGIONAL_REFERENCE ? 240 : 200) + Math.min(nextFeedbackCount, 50));
        entity.setConfidenceScore(Math.min(0.99d, 0.60d + (nextFeedbackCount * 0.03d)));
        entity.setCandidateSubtypesJson(codec.writeStringList(mergedCandidates));
        entity.setPhotoLocationsJson(codec.writeStringList(mergedPhotoLocations));
        entity.setCompositionJson(codec.writeComposition(mergedComposition));
        repository.save(entity);
    }

    private List<ExecutionPlanPayload.CameraEnvironmentProfile> buildObservedComposition(List<Map<String, Object>> reviewedCaptures) {
        Map<String, ObservedEnvironment> byLocation = new LinkedHashMap<>();
        for (Map<String, Object> item : reviewedCaptures) {
            String photoLocation = readPhotoLocation(item);
            if (isBlank(photoLocation)) {
                continue;
            }
            String macroLocal = readText(item, "subjectContext", "captureContext", "macroLocal");
            String element = readText(item, "targetQualifier", "targetQualifierLabel", "elemento");
            String material = resolveMaterial(item);
            String state = readText(item, "targetCondition", "conditionState", "estado");
            byLocation.computeIfAbsent(photoLocation, ignored -> new ObservedEnvironment(
                            blankToDefault(macroLocal, "Area interna"),
                            photoLocation
                    ))
                    .accept(blankToDefault(element, "Visao geral"), material, state);
        }
        return byLocation.values().stream().map(ObservedEnvironment::toProfile).toList();
    }

    private String resolveMaterial(Map<String, Object> values) {
        String direct = readText(values, "materialAttribute", "material");
        if (!isBlank(direct)) {
            return direct;
        }
        Object domainAttributes = values.get("domainAttributes");
        if (domainAttributes instanceof Map<?, ?> map) {
            Object material = map.get("inspection.material");
            if (material != null && !String.valueOf(material).isBlank()) {
                return String.valueOf(material).trim();
            }
        }
        return null;
    }

    private String readPhotoLocation(Map<String, Object> values) {
        return readText(values, "targetItemBase", "targetItemBaseLabel", "targetItem", "targetItemLabel", "ambiente");
    }

    private List<Map<String, Object>> extractMapList(Object value) {
        if (!(value instanceof List<?> list)) {
            return List.of();
        }
        List<Map<String, Object>> items = new ArrayList<>();
        for (Object entry : list) {
            if (entry instanceof Map<?, ?> rawMap) {
                Map<String, Object> normalized = new LinkedHashMap<>();
                rawMap.forEach((key, rawValue) -> {
                    if (key != null) {
                        normalized.put(String.valueOf(key), rawValue);
                    }
                });
                items.add(normalized);
            }
        }
        return List.copyOf(items);
    }

    private List<String> readStringList(Object value) {
        if (!(value instanceof List<?> list)) {
            return List.of();
        }
        List<String> resolved = new ArrayList<>();
        for (Object item : list) {
            if (item != null && !String.valueOf(item).isBlank()) {
                resolved.add(String.valueOf(item).trim());
            }
        }
        return List.copyOf(resolved);
    }

    private String readText(Map<String, Object> values, String... keys) {
        for (String key : keys) {
            Object raw = values.get(key);
            if (raw != null && !String.valueOf(raw).isBlank()) {
                return String.valueOf(raw).trim();
            }
        }
        return null;
    }

    private List<String> mergeValues(Collection<String> left, Collection<String> right) {
        LinkedHashSet<String> merged = new LinkedHashSet<>();
        if (left != null) {
            for (String item : left) {
                if (item != null && !item.isBlank()) {
                    merged.add(item.trim());
                }
            }
        }
        if (right != null) {
            for (String item : right) {
                if (item != null && !item.isBlank()) {
                    merged.add(item.trim());
                }
            }
        }
        return List.copyOf(merged);
    }

    private List<String> sanitizeValues(Collection<String> values) {
        return mergeValues(List.of(), values);
    }

    private String blankToNull(String value) {
        return isBlank(value) ? null : value.trim();
    }

    private String blankToDefault(String value, String fallback) {
        return isBlank(value) ? fallback : value.trim();
    }

    private boolean isBlank(String value) {
        return value == null || value.isBlank();
    }

    private String normalize(String value) {
        String normalized = value == null ? "" : value.trim().toLowerCase(Locale.ROOT);
        return Normalizer.normalize(normalized, Normalizer.Form.NFD).replaceAll("\\p{M}+", "");
    }

    private static final class ObservedEnvironment {
        private final String macroLocal;
        private final String photoLocation;
        private final Map<String, ObservedElement> elements = new LinkedHashMap<>();

        private ObservedEnvironment(String macroLocal, String photoLocation) {
            this.macroLocal = macroLocal;
            this.photoLocation = photoLocation;
        }

        private void accept(String element, String material, String state) {
            elements.computeIfAbsent(element, ObservedElement::new).accept(material, state);
        }

        private ExecutionPlanPayload.CameraEnvironmentProfile toProfile() {
            return new ExecutionPlanPayload.CameraEnvironmentProfile(
                    macroLocal,
                    photoLocation,
                    false,
                    1,
                    elements.values().stream().map(ObservedElement::toProfile).toList(),
                    "COMPOSITION",
                    List.of()
            );
        }
    }

    private static final class ObservedElement {
        private final String name;
        private final Set<String> materials = new LinkedHashSet<>();
        private final Set<String> states = new LinkedHashSet<>();

        private ObservedElement(String name) {
            this.name = name;
        }

        private void accept(String material, String state) {
            if (material != null && !material.isBlank()) {
                materials.add(material.trim());
            }
            if (state != null && !state.isBlank()) {
                states.add(state.trim());
            }
        }

        private ExecutionPlanPayload.CameraElementProfile toProfile() {
            return new ExecutionPlanPayload.CameraElementProfile(
                    name,
                    List.copyOf(materials),
                    List.copyOf(states)
            );
        }
    }
}
