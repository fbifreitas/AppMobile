package com.appbackoffice.api.intelligence.service;

import com.appbackoffice.api.intelligence.dto.OperationalReferenceRebuildResponse;
import com.appbackoffice.api.intelligence.entity.ExecutionPlanSnapshotEntity;
import com.appbackoffice.api.intelligence.entity.ExecutionPlanStatus;
import com.appbackoffice.api.intelligence.entity.OperationalReferenceProfileEntity;
import com.appbackoffice.api.intelligence.entity.OperationalReferenceScope;
import com.appbackoffice.api.intelligence.entity.OperationalReferenceSourceType;
import com.appbackoffice.api.intelligence.model.ExecutionPlanPayload;
import com.appbackoffice.api.intelligence.repository.ExecutionPlanSnapshotRepository;
import com.appbackoffice.api.intelligence.repository.OperationalReferenceProfileRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.text.Normalizer;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Collection;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;

@Service
public class OperationalReferenceRebuildService {

    private final ExecutionPlanSnapshotRepository snapshotRepository;
    private final OperationalReferenceProfileRepository repository;
    private final OperationalReferenceProfileCodec codec;
    private final ObjectMapper objectMapper;
    private final OperationalReferenceCompositionSupport compositionSupport;
    private final OperationalReferenceRegionResolver regionResolver;

    public OperationalReferenceRebuildService(ExecutionPlanSnapshotRepository snapshotRepository,
                                              OperationalReferenceProfileRepository repository,
                                              OperationalReferenceProfileCodec codec,
                                              ObjectMapper objectMapper,
                                              OperationalReferenceCompositionSupport compositionSupport,
                                              OperationalReferenceRegionResolver regionResolver) {
        this.snapshotRepository = snapshotRepository;
        this.repository = repository;
        this.codec = codec;
        this.objectMapper = objectMapper;
        this.compositionSupport = compositionSupport;
        this.regionResolver = regionResolver;
    }

    @Transactional
    public OperationalReferenceRebuildResponse rebuild(String tenantId) {
        List<ExecutionPlanSnapshotEntity> snapshots = snapshotRepository.findByTenantIdAndStatusInOrderByCreatedAtDesc(
                tenantId,
                List.of(ExecutionPlanStatus.PUBLISHED, ExecutionPlanStatus.REVIEW_REQUIRED)
        );

        List<OperationalReferenceProfileEntity> existing = repository.findAllByOrderByPriorityWeightDescIdAsc();
        List<OperationalReferenceProfileEntity> toDelete = existing.stream()
                .filter(item -> tenantId.equalsIgnoreCase(item.getTenantId()))
                .filter(item -> item.getScopeType() == OperationalReferenceScope.HISTORICAL_REFERENCE
                        || item.getScopeType() == OperationalReferenceScope.REGIONAL_REFERENCE)
                .toList();
        if (!toDelete.isEmpty()) {
            repository.deleteAll(toDelete);
        }

        Map<String, Aggregate> historical = new LinkedHashMap<>();
        Map<String, Aggregate> regional = new LinkedHashMap<>();
        for (ExecutionPlanSnapshotEntity snapshot : snapshots) {
            JsonNode root = read(snapshot.getPlanJson());
            JsonNode propertyProfile = root.path("propertyProfile");
            String assetType = text(propertyProfile, "canonicalAssetType");
            String assetSubtype = text(propertyProfile, "canonicalAssetSubtype");
            if (assetType == null || assetSubtype == null) {
                continue;
            }
            String refinedAssetSubtype = text(propertyProfile, "refinedAssetSubtype");
            String propertyStandard = text(propertyProfile, "propertyStandard");
            String address = text(propertyProfile, "address");
            OperationalReferenceRegionResolver.Region region = regionResolver.resolve(address);
            List<String> candidates = readStringList(propertyProfile.path("candidateAssetSubtypes"));
            JsonNode compositionNode = root.path("cameraConfig").path("compositionProfiles");
            List<ExecutionPlanPayload.CameraEnvironmentProfile> composition = readComposition(compositionNode);
            if (composition.isEmpty()) {
                continue;
            }

            String historicalKey = String.join("::", normalize(assetType), normalize(assetSubtype), normalize(refinedAssetSubtype), normalize(propertyStandard));
            historical.computeIfAbsent(historicalKey, ignored -> new Aggregate(assetType, assetSubtype, refinedAssetSubtype, propertyStandard, null, null, null))
                    .accumulate(candidates, composition, compositionSupport);

            if (region.city() != null && !region.city().isBlank()) {
                String regionalKey = String.join("::", normalize(assetType), normalize(assetSubtype), normalize(refinedAssetSubtype), normalize(propertyStandard), normalize(region.state()), normalize(region.city()), normalize(region.district()));
                regional.computeIfAbsent(regionalKey, ignored -> new Aggregate(assetType, assetSubtype, refinedAssetSubtype, propertyStandard, region.state(), region.city(), region.district()))
                        .accumulate(candidates, composition, compositionSupport);
            }
        }

        List<OperationalReferenceProfileEntity> rebuilt = new ArrayList<>();
        historical.values().forEach(aggregate -> rebuilt.add(aggregate.toEntity(tenantId, OperationalReferenceScope.HISTORICAL_REFERENCE, OperationalReferenceSourceType.HISTORICAL_AGGREGATE, codec, 180)));
        regional.values().forEach(aggregate -> rebuilt.add(aggregate.toEntity(tenantId, OperationalReferenceScope.REGIONAL_REFERENCE, OperationalReferenceSourceType.REGIONAL_HEURISTIC, codec, 220)));
        if (!rebuilt.isEmpty()) {
            repository.saveAll(rebuilt);
        }

        int totalProfiles = repository.findByActiveFlagTrueOrderByPriorityWeightDescIdAsc().stream()
                .filter(item -> item.getTenantId() == null || item.getTenantId().isBlank() || tenantId.equalsIgnoreCase(item.getTenantId()))
                .toList()
                .size();

        return new OperationalReferenceRebuildResponse(
                tenantId,
                historical.size(),
                regional.size(),
                totalProfiles,
                Instant.now().toString()
        );
    }

    private JsonNode read(String raw) {
        try {
            return objectMapper.readTree(raw);
        } catch (Exception exception) {
            throw new IllegalStateException("Failed to parse execution plan snapshot", exception);
        }
    }

    private List<String> readStringList(JsonNode node) {
        if (node == null || !node.isArray()) {
            return List.of();
        }
        List<String> values = new ArrayList<>();
        node.forEach(item -> {
            if (item != null && !item.asText("").isBlank()) {
                values.add(item.asText().trim());
            }
        });
        return List.copyOf(values);
    }

    private List<ExecutionPlanPayload.CameraEnvironmentProfile> readComposition(JsonNode node) {
        if (node == null || !node.isArray()) {
            return List.of();
        }
        try {
            return objectMapper.readerForListOf(ExecutionPlanPayload.CameraEnvironmentProfile.class).readValue(node);
        } catch (Exception exception) {
            throw new IllegalStateException("Failed to parse composition profiles from snapshot", exception);
        }
    }

    private String text(JsonNode node, String field) {
        String value = node.path(field).asText("");
        return value.isBlank() ? null : value.trim();
    }

    private String normalize(String value) {
        String normalized = value == null ? "" : value.trim().toLowerCase(Locale.ROOT);
        return Normalizer.normalize(normalized, Normalizer.Form.NFD).replaceAll("\\p{M}+", "");
    }

    private static final class Aggregate {
        private final String assetType;
        private final String assetSubtype;
        private final String refinedAssetSubtype;
        private final String propertyStandard;
        private final String regionState;
        private final String regionCity;
        private final String regionDistrict;
        private final Set<String> candidateSubtypes = new LinkedHashSet<>();
        private final Map<String, ExecutionPlanPayload.CameraEnvironmentProfile> compositionByLocation = new LinkedHashMap<>();
        private int observations = 0;

        private Aggregate(String assetType,
                          String assetSubtype,
                          String refinedAssetSubtype,
                          String propertyStandard,
                          String regionState,
                          String regionCity,
                          String regionDistrict) {
            this.assetType = assetType;
            this.assetSubtype = assetSubtype;
            this.refinedAssetSubtype = refinedAssetSubtype;
            this.propertyStandard = propertyStandard;
            this.regionState = regionState;
            this.regionCity = regionCity;
            this.regionDistrict = regionDistrict;
        }

        private void accumulate(Collection<String> candidates,
                                List<ExecutionPlanPayload.CameraEnvironmentProfile> composition,
                                OperationalReferenceCompositionSupport compositionSupport) {
            observations += 1;
            if (candidates != null) {
                candidateSubtypes.addAll(candidates);
            }
            for (ExecutionPlanPayload.CameraEnvironmentProfile item : composition) {
                compositionByLocation.merge(
                        item.photoLocation(),
                        item,
                        compositionSupport::mergeProfile
                );
            }
        }

        private OperationalReferenceProfileEntity toEntity(String tenantId,
                                                           OperationalReferenceScope scope,
                                                           OperationalReferenceSourceType sourceType,
                                                           OperationalReferenceProfileCodec codec,
                                                           int basePriority) {
            OperationalReferenceProfileEntity entity = new OperationalReferenceProfileEntity();
            entity.setTenantId(tenantId);
            entity.setScopeType(scope);
            entity.setSourceType(sourceType);
            entity.setActiveFlag(true);
            entity.setAssetType(assetType);
            entity.setAssetSubtype(assetSubtype);
            entity.setRefinedAssetSubtype(refinedAssetSubtype);
            entity.setPropertyStandard(propertyStandard);
            entity.setRegionState(regionState);
            entity.setRegionCity(regionCity);
            entity.setRegionDistrict(regionDistrict);
            entity.setPriorityWeight(basePriority + Math.min(observations, 50));
            entity.setConfidenceScore(Math.min(0.99d, 0.50d + (observations * 0.03d)));
            entity.setFeedbackCount(observations);
            entity.setCandidateSubtypesJson(codec.writeStringList(List.copyOf(candidateSubtypes)));
            entity.setPhotoLocationsJson(codec.writeStringList(new ArrayList<>(compositionByLocation.keySet())));
            entity.setCompositionJson(codec.writeComposition(new ArrayList<>(compositionByLocation.values())));
            return entity;
        }
    }
}
