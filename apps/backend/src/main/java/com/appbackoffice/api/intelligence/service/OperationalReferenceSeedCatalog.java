package com.appbackoffice.api.intelligence.service;

import com.appbackoffice.api.intelligence.model.ExecutionPlanPayload;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public final class OperationalReferenceSeedCatalog {

    private OperationalReferenceSeedCatalog() {
    }

    public static List<SeedProfile> globalSeedProfiles(OperationalCaptureCatalog captureCatalog) {
        return List.of(
                seed(captureCatalog, "Urbano", "Apartamento", null, null, 100, 0.88d),
                seed(captureCatalog, "Urbano", "Apartamento", "Apartamento padrao", "Padrao", 112, 0.90d),
                seed(captureCatalog, "Urbano", "Apartamento", "Apartamento alto padrao", "Alto padrao", 118, 0.92d),
                seed(captureCatalog, "Urbano", "Apartamento", "Duplex", "Superior", 120, 0.93d),
                seed(captureCatalog, "Urbano", "Apartamento", "Triplex", "Superior", 122, 0.93d),
                seed(captureCatalog, "Urbano", "Casa", null, null, 95, 0.87d),
                seed(captureCatalog, "Urbano", "Casa", "Casa geminada", "Padrao", 98, 0.89d),
                seed(captureCatalog, "Urbano", "Sobrado", null, null, 100, 0.89d),
                seed(captureCatalog, "Comercial", "Loja", null, null, 92, 0.87d),
                seed(captureCatalog, "Comercial", "Sala comercial", null, null, 92, 0.87d),
                seed(captureCatalog, "Industrial", "Galpao", null, null, 93, 0.88d),
                seed(captureCatalog, "Rural", "Sitio", null, null, 86, 0.84d),
                seed(captureCatalog, "Rural", "Chacara", null, null, 87, 0.84d),
                seed(captureCatalog, "Rural", "Fazenda", null, null, 89, 0.85d),
                seed(captureCatalog, "Urbano", "Terreno", null, null, 80, 0.82d)
        );
    }

    public static List<String> referencePhotoLocations(OperationalCaptureCatalog captureCatalog,
                                                       String assetType,
                                                       String assetSubtype,
                                                       String refinedAssetSubtype) {
        return referenceCompositionProfiles(captureCatalog, assetType, assetSubtype, refinedAssetSubtype)
                .stream()
                .map(ExecutionPlanPayload.CameraEnvironmentProfile::photoLocation)
                .toList();
    }

    public static List<ExecutionPlanPayload.CameraEnvironmentProfile> referenceCompositionProfiles(OperationalCaptureCatalog captureCatalog,
                                                                                                   String assetType,
                                                                                                   String assetSubtype,
                                                                                                   String refinedAssetSubtype) {
        return compositionFor(captureCatalog, assetType, assetSubtype, refinedAssetSubtype);
    }

    private static SeedProfile seed(OperationalCaptureCatalog captureCatalog,
                                    String assetType,
                                    String assetSubtype,
                                    String refinedAssetSubtype,
                                    String propertyStandard,
                                    int priorityWeight,
                                    double confidenceScore) {
        List<ExecutionPlanPayload.CameraEnvironmentProfile> composition = compositionFor(
                captureCatalog,
                assetType,
                assetSubtype,
                refinedAssetSubtype
        );
        return new SeedProfile(
                assetType,
                assetSubtype,
                refinedAssetSubtype,
                propertyStandard,
                priorityWeight,
                confidenceScore,
                captureCatalog.referenceCandidateSubtypes(assetType, assetSubtype),
                composition.stream().map(ExecutionPlanPayload.CameraEnvironmentProfile::photoLocation).toList(),
                composition
        );
    }

    private static List<ExecutionPlanPayload.CameraEnvironmentProfile> compositionFor(OperationalCaptureCatalog captureCatalog,
                                                                                      String assetType,
                                                                                      String assetSubtype,
                                                                                      String refinedAssetSubtype) {
        List<ExecutionPlanPayload.CameraEnvironmentProfile> base = new ArrayList<>(
                captureCatalog.referenceCompositionProfiles(assetType, assetSubtype)
        );
        if (refinedAssetSubtype == null || refinedAssetSubtype.isBlank()) {
            return List.copyOf(base);
        }
        return switch (refinedAssetSubtype) {
            case "Apartamento alto padrao" -> append(base,
                    environment("Area interna", "Hall privativo", false, 1, element("Visao geral"), element("Piso", "Porcelanato", "Pedra"), element("Parede", "Pintura")),
                    environment("Area interna", "Lavabo", false, 1, element("Visao geral"), element("Pia", "Pedra", "Inox"), element("Torneira", "Metal", "Inox")),
                    environment("Area interna", "Espaco gourmet", false, 1, element("Visao geral"), element("Bancada", "Pedra", "Porcelanato"), element("Churrasqueira", "Metal", "Pedra"))
            );
            case "Duplex" -> append(base,
                    environment("Area interna", "Escada interna", false, 1, element("Visao geral"), element("Corrimao", "Metal", "Madeira"), element("Piso", "Madeira", "Porcelanato", "Pedra")),
                    environment("Area interna", "Pavimento superior", false, 1, element("Visao geral"), element("Parede", "Pintura"), element("Teto", "Pintura", "Forro")),
                    environment("Area externa", "Terraco", false, 1, element("Visao geral"), element("Guarda-corpo", "Metal", "Vidro"), element("Piso", "Pedra", "Porcelanato"))
            );
            case "Triplex" -> append(base,
                    environment("Area interna", "Escada interna", false, 1, element("Visao geral"), element("Corrimao", "Metal", "Madeira"), element("Piso", "Madeira", "Porcelanato", "Pedra")),
                    environment("Area interna", "Pavimento intermediario", false, 1, element("Visao geral"), element("Parede", "Pintura"), element("Teto", "Pintura", "Forro")),
                    environment("Area externa", "Terraco", false, 1, element("Visao geral"), element("Guarda-corpo", "Metal", "Vidro"), element("Piso", "Pedra", "Porcelanato"))
            );
            case "Casa geminada" -> append(base,
                    environment("Rua", "Fachada lateral", false, 1, element("Visao geral"), element("Parede", "Pintura"), element("Janela", "Vidro", "Aluminio")),
                    environment("Area externa", "Corredor lateral", false, 1, element("Visao geral"), element("Piso", "Concreto", "Ceramica"), element("Parede", "Pintura", "Concreto"))
            );
            default -> List.copyOf(base);
        };
    }

    private static List<ExecutionPlanPayload.CameraEnvironmentProfile> append(
            List<ExecutionPlanPayload.CameraEnvironmentProfile> base,
            ExecutionPlanPayload.CameraEnvironmentProfile... extras
    ) {
        Map<String, ExecutionPlanPayload.CameraEnvironmentProfile> ordered = new LinkedHashMap<>();
        base.forEach(item -> ordered.put(item.photoLocation(), item));
        for (ExecutionPlanPayload.CameraEnvironmentProfile extra : extras) {
            ordered.put(extra.photoLocation(), extra);
        }
        return List.copyOf(ordered.values());
    }

    private static ExecutionPlanPayload.CameraEnvironmentProfile environment(String macroLocal,
                                                                             String photoLocation,
                                                                             boolean required,
                                                                             int minPhotos,
                                                                             ExecutionPlanPayload.CameraElementProfile... elements) {
        return new ExecutionPlanPayload.CameraEnvironmentProfile(
                macroLocal,
                photoLocation,
                required,
                minPhotos,
                List.of(elements),
                "COMPOSITION",
                List.of()
        );
    }

    private static ExecutionPlanPayload.CameraElementProfile element(String name, String... materials) {
        return new ExecutionPlanPayload.CameraElementProfile(
                name,
                List.of(materials),
                List.of("Novo", "Bom", "Regular", "Ruim", "Pessimo")
        );
    }

    public record SeedProfile(
            String assetType,
            String assetSubtype,
            String refinedAssetSubtype,
            String propertyStandard,
            int priorityWeight,
            double confidenceScore,
            List<String> candidateSubtypes,
            List<String> photoLocations,
            List<ExecutionPlanPayload.CameraEnvironmentProfile> compositionProfiles
    ) {
    }
}
