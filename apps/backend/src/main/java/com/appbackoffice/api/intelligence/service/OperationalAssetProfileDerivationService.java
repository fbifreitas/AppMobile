package com.appbackoffice.api.intelligence.service;

import com.appbackoffice.api.intelligence.model.DerivedOperationalAssetProfile;
import com.appbackoffice.api.intelligence.model.ExecutionPlanPayload;
import com.appbackoffice.api.intelligence.model.ResolvedOperationalReferenceProfile;
import com.appbackoffice.api.intelligence.port.ResearchProviderResponse;
import com.appbackoffice.api.job.entity.InspectionCase;
import org.springframework.stereotype.Service;

import java.text.Normalizer;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Optional;
import java.util.Set;

@Service
public class OperationalAssetProfileDerivationService {
    private static final String UNRESOLVED_SUBTYPE = "Indefinido";
    private static final String REVIEW_REASON_INSUFFICIENT_SUBTYPE_EVIDENCE = "INSUFFICIENT_STRUCTURAL_EVIDENCE_FOR_SUBTYPE";
    private static final String REVIEW_REASON_CONFLICTING_SUBTYPE_SIGNALS = "CONFLICTING_SUBTYPE_SIGNALS";

    private final ResearchFactResolver factResolver;
    private final OperationalCaptureCatalog captureCatalog;
    private final OperationalReferenceCatalogService operationalReferenceCatalogService;
    private final NormativeMatrixService normativeMatrixService;
    private final NormativeCameraTreeOverlayService normativeCameraTreeOverlayService;

    public OperationalAssetProfileDerivationService(ResearchFactResolver factResolver,
                                                    OperationalCaptureCatalog captureCatalog,
                                                    OperationalReferenceCatalogService operationalReferenceCatalogService,
                                                    NormativeMatrixService normativeMatrixService,
                                                    NormativeCameraTreeOverlayService normativeCameraTreeOverlayService) {
        this.factResolver = factResolver;
        this.captureCatalog = captureCatalog;
        this.operationalReferenceCatalogService = operationalReferenceCatalogService;
        this.normativeMatrixService = normativeMatrixService;
        this.normativeCameraTreeOverlayService = normativeCameraTreeOverlayService;
    }

    public DerivedOperationalAssetProfile derive(InspectionCase inspectionCase,
                                                 ResearchProviderResponse providerResponse) {
        String taxonomy = factResolver.firstValue(providerResponse, "property_taxonomy")
                .orElseGet(() -> defaultTaxonomy(inspectionCase));
        String canonicalAssetType = inferCanonicalAssetType(inspectionCase, providerResponse, taxonomy);
        SubtypeResolution subtypeResolution = inferCanonicalAssetSubtype(inspectionCase, providerResponse, canonicalAssetType);
        String canonicalAssetSubtype = subtypeResolution.canonicalAssetSubtype();
        String refinedAssetSubtype = inferRefinedSubtype(providerResponse, canonicalAssetSubtype);
        String propertyStandard = inferPropertyStandard(providerResponse, canonicalAssetSubtype);
        List<String> candidateAssetSubtypes = mergeCandidates(
                subtypeResolution.candidateAssetSubtypes(),
                inferCandidateAssetSubtypes(
                providerResponse,
                canonicalAssetSubtype,
                refinedAssetSubtype,
                propertyStandard
                )
        );
        ResolvedOperationalReferenceProfile referenceProfile = operationalReferenceCatalogService.resolve(
                inspectionCase,
                providerResponse,
                canonicalAssetType,
                canonicalAssetSubtype,
                refinedAssetSubtype,
                propertyStandard
        );
        candidateAssetSubtypes = subtypeResolution.subtypeResolved()
                ? mergeCandidates(candidateAssetSubtypes, referenceProfile.candidateAssetSubtypes())
                : mergeCandidates(candidateAssetSubtypes, referenceProfile.candidateAssetSubtypes())
                    .stream()
                    .filter(candidate -> !containsAny(candidate, UNRESOLVED_SUBTYPE, canonicalAssetType))
                    .toList();
        List<String> baseLocations = referenceProfile.photoLocations().isEmpty()
                ? captureCatalog.defaultPhotoLocations(canonicalAssetType, canonicalAssetSubtype)
                : referenceProfile.photoLocations();
        List<String> availablePhotoLocations = captureCatalog.enrichWithCompositionSignals(baseLocations, factResolver, providerResponse);
        List<ExecutionPlanPayload.CameraEnvironmentProfile> compositionProfiles = mergeCompositionProfiles(
                referenceProfile.compositionProfiles(),
                captureCatalog.buildCompositionProfiles(canonicalAssetType, canonicalAssetSubtype, availablePhotoLocations),
                availablePhotoLocations
        );
        String initialContext = captureCatalog.resolveInitialContext(
                canonicalAssetType,
                canonicalAssetSubtype,
                availablePhotoLocations,
                compositionProfiles
        );
        ExecutionPlanPayload.StructuralFacts structuralFacts = inferStructuralFacts(
                providerResponse,
                availablePhotoLocations,
                compositionProfiles,
                refinedAssetSubtype
        );
        List<ExecutionPlanPayload.CapturePlanItem> capturePlan = captureCatalog.buildCapturePlan(
                compositionProfiles,
                initialContext
        );
        var normativeProfile = normativeMatrixService.resolveProfile(
                canonicalAssetType,
                canonicalAssetSubtype,
                refinedAssetSubtype
        );
        var overlayResult = normativeCameraTreeOverlayService.apply(
                canonicalAssetType,
                canonicalAssetSubtype,
                refinedAssetSubtype,
                compositionProfiles,
                capturePlan,
                normativeProfile
        );
        compositionProfiles = overlayResult.compositionProfiles();
        capturePlan = overlayResult.capturePlan();
        availablePhotoLocations = compositionProfiles.stream()
                .map(ExecutionPlanPayload.CameraEnvironmentProfile::photoLocation)
                .distinct()
                .toList();
        initialContext = captureCatalog.resolveInitialContext(
                canonicalAssetType,
                canonicalAssetSubtype,
                availablePhotoLocations,
                compositionProfiles
        );
        return new DerivedOperationalAssetProfile(
                canonicalAssetType,
                canonicalAssetSubtype,
                candidateAssetSubtypes,
                refinedAssetSubtype,
                propertyStandard,
                taxonomy,
                initialContext,
                subtypeResolution.requiresManualReview(),
                subtypeResolution.subtypeResolved(),
                subtypeResolution.reviewReasons(),
                structuralFacts,
                availablePhotoLocations,
                capturePlan,
                compositionProfiles
        );
    }

    private List<String> inferCandidateAssetSubtypes(ResearchProviderResponse providerResponse,
                                                     String canonicalSubtype,
                                                     String refinedSubtype,
                                                     String propertyStandard) {
        Set<String> candidates = new LinkedHashSet<>();
        addCandidate(candidates, canonicalSubtype);
        addCandidate(candidates, refinedSubtype);

        Optional<String> explicitCandidates = factResolver.firstValue(
                providerResponse,
                "candidate_asset_subtypes",
                "candidate_property_subtypes",
                "property_subtype_candidates"
        );
        explicitCandidates.ifPresent(value -> {
            for (String item : value.split("[,;|]")) {
                addCandidate(candidates, item);
            }
        });

        if ("Apartamento".equalsIgnoreCase(canonicalSubtype)) {
            if (factResolver.containsText(providerResponse, "duplex")) {
                addCandidate(candidates, "Duplex");
            }
            if (factResolver.containsText(providerResponse, "triplex")) {
                addCandidate(candidates, "Triplex");
            }
            if (containsAny(propertyStandard, "alto padrao")) {
                addCandidate(candidates, "Apartamento alto padrao");
            }
            if (containsAny(propertyStandard, "padrao")) {
                addCandidate(candidates, "Apartamento padrao");
            }
        }
        if ("Casa".equalsIgnoreCase(canonicalSubtype) || "Sobrado".equalsIgnoreCase(canonicalSubtype)) {
            addCandidate(candidates, "Casa");
            if (factResolver.containsText(providerResponse, "sobrado")) {
                addCandidate(candidates, "Sobrado");
            }
            if (factResolver.containsText(providerResponse, "casa geminada", "geminada")) {
                addCandidate(candidates, "Casa geminada");
            }
        }

        return List.copyOf(candidates);
    }

    private List<String> mergeCandidates(List<String> left, List<String> right) {
        Set<String> merged = new LinkedHashSet<>();
        if (left != null) {
            merged.addAll(left);
        }
        if (right != null) {
            merged.addAll(right);
        }
        return List.copyOf(merged);
    }

    private List<ExecutionPlanPayload.CameraEnvironmentProfile> mergeCompositionProfiles(
            List<ExecutionPlanPayload.CameraEnvironmentProfile> primary,
            List<ExecutionPlanPayload.CameraEnvironmentProfile> fallback,
            List<String> preferredOrder
    ) {
        Set<String> orderedLocations = new LinkedHashSet<>(preferredOrder);
        primary.forEach(item -> orderedLocations.add(item.photoLocation()));
        fallback.forEach(item -> orderedLocations.add(item.photoLocation()));

        List<ExecutionPlanPayload.CameraEnvironmentProfile> merged = new java.util.ArrayList<>();
        for (String location : orderedLocations) {
            ExecutionPlanPayload.CameraEnvironmentProfile selected = primary.stream()
                    .filter(item -> normalize(item.photoLocation()).equals(normalize(location)))
                    .findFirst()
                    .orElseGet(() -> fallback.stream()
                            .filter(item -> normalize(item.photoLocation()).equals(normalize(location)))
                            .findFirst()
                            .orElse(null));
            if (selected != null) {
                merged.add(selected);
            }
        }
        return List.copyOf(merged);
    }

    private String inferCanonicalAssetType(InspectionCase inspectionCase,
                                           ResearchProviderResponse providerResponse,
                                           String taxonomy) {
        Optional<String> explicit = factResolver.firstValue(
                providerResponse,
                "property_type",
                "canonical_asset_type",
                "asset_type"
        );
        if (explicit.isPresent()) {
            return mapAssetType(explicit.get());
        }
        if (containsAny(taxonomy, "commercial", "comercial")) {
            return "Comercial";
        }
        if (containsAny(taxonomy, "industrial")) {
            return "Industrial";
        }
        if (containsAny(taxonomy, "rural", "sitio", "sítio", "fazenda", "chacara", "chácara")) {
            return "Rural";
        }
        return mapAssetType(inspectionCase.getInspectionType());
    }

    private SubtypeResolution inferCanonicalAssetSubtype(InspectionCase inspectionCase,
                                                         ResearchProviderResponse providerResponse,
                                                         String canonicalAssetType) {
        Optional<String> explicit = factResolver.firstValue(
                providerResponse,
                "property_subtype",
                "canonical_asset_subtype",
                "property_hypothesis"
        );
        if (explicit.isPresent()) {
            String subtype = mapAssetSubtype(explicit.get(), canonicalAssetType);
            return resolvedSubtype(subtype);
        }
        if ("Rural".equalsIgnoreCase(canonicalAssetType)) {
            return resolvedSubtype("Sitio");
        }
        if ("Comercial".equalsIgnoreCase(canonicalAssetType)) {
            return resolvedSubtype("Loja");
        }
        if ("Industrial".equalsIgnoreCase(canonicalAssetType)) {
            return resolvedSubtype("Galpao");
        }
        if (!"Urbano".equalsIgnoreCase(canonicalAssetType)) {
            return resolvedSubtype("Imovel");
        }

        Set<String> strongCandidates = new LinkedHashSet<>();
        inferSubtypeFromInspectionType(inspectionCase.getInspectionType()).ifPresent(strongCandidates::add);
        inferSubtypeFromAddress(inspectionCase.getPropertyAddress()).ifPresent(strongCandidates::add);
        inferUrbanSubtypeFromSignals(providerResponse).ifPresent(strongCandidates::add);

        List<String> candidates = List.copyOf(strongCandidates);
        if (candidates.size() == 1) {
            return resolvedSubtype(candidates.getFirst(), candidates);
        }
        if (candidates.size() > 1) {
            return unresolvedSubtype(candidates, REVIEW_REASON_CONFLICTING_SUBTYPE_SIGNALS);
        }
        return unresolvedSubtype(List.of("Casa", "Sobrado", "Apartamento", "Terreno"), REVIEW_REASON_INSUFFICIENT_SUBTYPE_EVIDENCE);
    }

    private Optional<String> inferUrbanSubtypeFromSignals(ResearchProviderResponse providerResponse) {
        if (factResolver.containsText(providerResponse, "apartamento", "condominio", "condominium", "missing_unit_identification")) {
            return Optional.of("Apartamento");
        }
        if (factResolver.containsText(providerResponse, "sobrado")) {
            return Optional.of("Sobrado");
        }
        if (factResolver.containsText(providerResponse, "casa geminada", "casa")) {
            return Optional.of("Casa");
        }
        if (factResolver.containsText(providerResponse, "terreno", "lote")) {
            return Optional.of("Terreno");
        }
        return Optional.empty();
    }

    private String inferRefinedSubtype(ResearchProviderResponse providerResponse, String canonicalSubtype) {
        Optional<String> explicit = factResolver.firstValue(providerResponse, "refined_subtype", "property_variant");
        if (explicit.isPresent()) {
            return explicit.get().trim();
        }
        if (factResolver.containsText(providerResponse, "duplex")) {
            return "Duplex";
        }
        if (factResolver.containsText(providerResponse, "triplex")) {
            return "Triplex";
        }
        return canonicalSubtype;
    }

    private String inferPropertyStandard(ResearchProviderResponse providerResponse, String canonicalSubtype) {
        if (isUndefinedSubtype(canonicalSubtype)) {
            return "Indeterminado";
        }
        double area = parseArea(providerResponse);
        if ("Apartamento".equalsIgnoreCase(canonicalSubtype)) {
            if (area >= 250d) {
                return "Alto padrao";
            }
            if (area > 0d) {
                return "Padrao";
            }
        }
        if ("Casa".equalsIgnoreCase(canonicalSubtype) || "Sobrado".equalsIgnoreCase(canonicalSubtype)) {
            if (area >= 250d) {
                return "Alto padrao";
            }
            if (area > 0d) {
                return "Padrao";
            }
        }
        return area > 0d ? "Padrao" : "Indeterminado";
    }

    private double parseArea(ResearchProviderResponse providerResponse) {
        return factResolver.firstValue(
                        providerResponse,
                        "private_area_m2",
                        "built_area_m2",
                        "property_area_m2",
                        "area_m2"
                )
                .map(value -> value.replace(",", ".").replaceAll("[^0-9.]", ""))
                .map(value -> {
                    try {
                        return Double.parseDouble(value);
                    } catch (NumberFormatException ignored) {
                        return 0d;
                    }
                })
                .orElse(0d);
    }

    private ExecutionPlanPayload.StructuralFacts inferStructuralFacts(
            ResearchProviderResponse providerResponse,
            List<String> availablePhotoLocations,
            List<ExecutionPlanPayload.CameraEnvironmentProfile> compositionProfiles,
            String refinedAssetSubtype
    ) {
        Set<String> normalizedLocations = new LinkedHashSet<>();
        for (String location : availablePhotoLocations) {
            normalizedLocations.add(normalize(location));
        }
        for (ExecutionPlanPayload.CameraEnvironmentProfile profile : compositionProfiles) {
            normalizedLocations.add(normalize(profile.photoLocation()));
        }

        boolean hasKitchen = hasLocation(normalizedLocations, "cozinha") || factResolver.containsText(providerResponse, "cozinha", "kitchen");
        boolean hasLivingRoom = hasLocation(normalizedLocations, "sala de estar") || factResolver.containsText(providerResponse, "sala de estar", "living room");
        boolean hasDiningRoom = hasLocation(normalizedLocations, "sala de jantar") || factResolver.containsText(providerResponse, "sala de jantar", "dining room");
        boolean hasLaundry = hasLocation(normalizedLocations, "lavanderia") || factResolver.containsText(providerResponse, "lavanderia", "laundry");
        boolean hasBalcony = hasLocation(normalizedLocations, "varanda", "terraco") || factResolver.containsText(providerResponse, "varanda", "sacada", "balcony", "terraco", "terrace");
        boolean hasGarage = hasLocation(normalizedLocations, "garagem", "vaga de garagem", "vaga") || factResolver.containsText(providerResponse, "garagem", "vaga", "garage");
        boolean hasPool = hasLocation(normalizedLocations, "piscina") || factResolver.containsText(providerResponse, "piscina", "pool");
        boolean hasGym = hasLocation(normalizedLocations, "academia") || factResolver.containsText(providerResponse, "academia", "gym");
        boolean hasPartyRoom = hasLocation(normalizedLocations, "salao de festas") || factResolver.containsText(providerResponse, "salao de festas", "party room");
        boolean hasBarbecueArea = hasLocation(normalizedLocations, "churrasqueira", "espaco gourmet") || factResolver.containsText(providerResponse, "churrasqueira", "barbecue", "espaco gourmet", "gourmet");
        boolean hasPlayground = hasLocation(normalizedLocations, "playground") || factResolver.containsText(providerResponse, "playground");
        boolean hasInternalStair =
                hasLocation(normalizedLocations, "escada interna") ||
                factResolver.containsText(providerResponse, "escada interna", "internal stair", "internal stairs", "duplex", "triplex") ||
                containsAny(refinedAssetSubtype, "Duplex", "Triplex");
        boolean hasUpperFloor =
                hasLocation(normalizedLocations, "pavimento superior", "terraco") ||
                factResolver.containsText(providerResponse, "pavimento superior", "andar superior", "upper floor", "duplex", "triplex") ||
                containsAny(refinedAssetSubtype, "Duplex", "Triplex");
        boolean hasIntermediateFloor =
                hasLocation(normalizedLocations, "pavimento intermediario") ||
                factResolver.containsText(providerResponse, "pavimento intermediario", "intermediate floor", "triplex") ||
                containsAny(refinedAssetSubtype, "Triplex");

        return new ExecutionPlanPayload.StructuralFacts(
                parseCount(providerResponse, "bedrooms_count", "bedroom_count", "rooms_count", "dormitorios", "quartos"),
                parseCount(providerResponse, "bathrooms_count", "bathroom_count", "banheiros"),
                parseCount(providerResponse, "suites_count", "suite_count", "suites"),
                parseCount(providerResponse, "garage_spots_count", "garage_count", "parking_spots_count", "vagas"),
                hasKitchen,
                hasLivingRoom,
                hasDiningRoom,
                hasLaundry,
                hasBalcony,
                hasGarage,
                hasPool,
                hasGym,
                hasPartyRoom,
                hasBarbecueArea,
                hasPlayground,
                hasInternalStair,
                hasUpperFloor,
                hasIntermediateFloor
        );
    }

    private Integer parseCount(ResearchProviderResponse providerResponse, String... keys) {
        return factResolver.firstValue(providerResponse, keys)
                .map(value -> value.replace(",", ".").replaceAll("[^0-9]", ""))
                .filter(value -> !value.isBlank())
                .map(value -> {
                    try {
                        return Integer.parseInt(value);
                    } catch (NumberFormatException ignored) {
                        return null;
                    }
                })
                .orElse(null);
    }

    private boolean hasLocation(Set<String> normalizedLocations, String... expectedFragments) {
        for (String fragment : expectedFragments) {
            String normalizedFragment = normalize(fragment);
            for (String location : normalizedLocations) {
                if (location.contains(normalizedFragment)) {
                    return true;
                }
            }
        }
        return false;
    }

    private String defaultTaxonomy(InspectionCase inspectionCase) {
        return inspectionCase.getInspectionType() == null ? "UNKNOWN" : inspectionCase.getInspectionType();
    }

    private String mapAssetType(String raw) {
        String normalized = normalize(raw);
        if (normalized.contains("rural") || normalized.contains("fazenda") || normalized.contains("sitio") || normalized.contains("chacara")) {
            return "Rural";
        }
        if (normalized.contains("industrial") || normalized.contains("galpao") || normalized.contains("fabrica")) {
            return "Industrial";
        }
        if (normalized.contains("comercial") || normalized.contains("loja") || normalized.contains("sala comercial")) {
            return "Comercial";
        }
        return "Urbano";
    }

    private String mapAssetSubtype(String raw, String canonicalAssetType) {
        String normalized = normalize(raw);
        if (normalized.contains("triplex")) {
            return "Apartamento";
        }
        if (normalized.contains("duplex")) {
            return "Apartamento";
        }
        if (normalized.contains("apart")) {
            return "Apartamento";
        }
        if (normalized.contains("sobrado")) {
            return "Sobrado";
        }
        if (normalized.contains("casa geminada") || normalized.contains("casa")) {
            return "Casa";
        }
        if (normalized.contains("terreno") || normalized.contains("lote")) {
            return "Terreno";
        }
        if (normalized.contains("sitio")) {
            return "Sitio";
        }
        if (normalized.contains("chacara")) {
            return "Chacara";
        }
        if (normalized.contains("fazenda")) {
            return "Fazenda";
        }
        if (normalized.contains("loja")) {
            return "Loja";
        }
        if (normalized.contains("sala") || normalized.contains("escritorio") || normalized.contains("consultorio") || normalized.contains("conjunto")) {
            return "Sala comercial";
        }
        if (normalized.contains("galpao")) {
            return "Galpao";
        }
        return switch (canonicalAssetType) {
            case "Rural" -> "Sitio";
            case "Comercial" -> "Loja";
            case "Industrial" -> "Galpao";
            default -> UNRESOLVED_SUBTYPE;
        };
    }

    private Optional<String> inferSubtypeFromInspectionType(String rawInspectionType) {
        String normalized = normalize(rawInspectionType);
        if (normalized.contains("house") || normalized.equals("casa")) {
            return Optional.of("Casa");
        }
        if (normalized.contains("sobrado") || normalized.contains("townhouse")) {
            return Optional.of("Sobrado");
        }
        if (normalized.contains("apartment") || normalized.contains("apartamento") || normalized.equals("apto")) {
            return Optional.of("Apartamento");
        }
        if (normalized.contains("land") || normalized.contains("terrain") || normalized.contains("terreno") || normalized.contains("lote")) {
            return Optional.of("Terreno");
        }
        return Optional.empty();
    }

    private Optional<String> inferSubtypeFromAddress(String address) {
        String normalized = normalize(address);
        if (normalized.contains(" sobrado")) {
            return Optional.of("Sobrado");
        }
        if (normalized.contains(" apto") || normalized.contains(" apartamento") || normalized.contains(" bloco") || normalized.contains(" torre") || normalized.contains(" condominio")) {
            return Optional.of("Apartamento");
        }
        if (normalized.contains(" casa ")) {
            return Optional.of("Casa");
        }
        if (normalized.contains(" lote") || normalized.contains(" terreno")) {
            return Optional.of("Terreno");
        }
        return Optional.empty();
    }

    private SubtypeResolution resolvedSubtype(String subtype) {
        return resolvedSubtype(subtype, List.of(subtype));
    }

    private SubtypeResolution resolvedSubtype(String subtype, List<String> candidates) {
        return new SubtypeResolution(subtype, List.copyOf(candidates), false, true, List.of());
    }

    private SubtypeResolution unresolvedSubtype(List<String> candidates, String reviewReason) {
        return new SubtypeResolution(
                UNRESOLVED_SUBTYPE,
                List.copyOf(candidates),
                true,
                false,
                List.of(reviewReason)
        );
    }

    private boolean isUndefinedSubtype(String canonicalSubtype) {
        return containsAny(canonicalSubtype, UNRESOLVED_SUBTYPE, "Imovel");
    }

    private boolean containsAny(String text, String... fragments) {
        String normalized = normalize(text);
        for (String fragment : fragments) {
            if (normalized.contains(normalize(fragment))) {
                return true;
            }
        }
        return false;
    }

    private String normalize(String value) {
        String normalized = value == null ? "" : value.trim().toLowerCase(Locale.ROOT);
        return Normalizer.normalize(normalized, Normalizer.Form.NFD)
                .replaceAll("\\p{M}+", "");
    }

    private void addCandidate(Set<String> target, String value) {
        String normalized = value == null ? "" : value.trim();
        if (normalized.isEmpty()) {
            return;
        }
        target.add(normalized);
    }

    private record SubtypeResolution(
            String canonicalAssetSubtype,
            List<String> candidateAssetSubtypes,
            boolean requiresManualReview,
            boolean subtypeResolved,
            List<String> reviewReasons
    ) {
    }
}
