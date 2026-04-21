package com.appbackoffice.api.intelligence.service;

import com.appbackoffice.api.intelligence.dto.NormativeMatrixResponse;
import com.appbackoffice.api.intelligence.model.ExecutionPlanPayload;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;

@Service
public class NormativeCameraTreeOverlayService {

    public OverlayResult apply(String assetType,
                               String assetSubtype,
                               String refinedAssetSubtype,
                               List<ExecutionPlanPayload.CameraEnvironmentProfile> baseComposition,
                               List<ExecutionPlanPayload.CapturePlanItem> baseCapturePlan,
                               NormativeMatrixResponse.Profile normativeProfile) {
        Map<String, ExecutionPlanPayload.CameraEnvironmentProfile> compositionByLocation = new LinkedHashMap<>();
        for (ExecutionPlanPayload.CameraEnvironmentProfile profile : baseComposition) {
            compositionByLocation.put(normalize(profile.photoLocation()), profile);
        }

        Map<String, ExecutionPlanPayload.CapturePlanItem> capturePlanByLocation = new LinkedHashMap<>();
        for (ExecutionPlanPayload.CapturePlanItem item : baseCapturePlan) {
            capturePlanByLocation.put(normalize(item.environment()), item);
        }

        if (normativeProfile != null && normativeProfile.rules() != null) {
            for (NormativeMatrixResponse.RuleItem rule : normativeProfile.rules()) {
                ExecutionPlanPayload.NormativeBinding binding = toBinding(rule);
                for (NormativeEnvironmentSpec spec : resolveSpecs(assetType, assetSubtype, refinedAssetSubtype, rule)) {
                    compositionByLocation.merge(
                            normalize(spec.photoLocation()),
                            spec.toEnvironmentProfile(binding),
                            (left, right) -> mergeEnvironment(left, right, binding)
                    );
                    capturePlanByLocation.merge(
                            normalize(spec.photoLocation()),
                            spec.toCapturePlanItem(binding),
                            (left, right) -> mergeCapturePlanItem(left, right, binding)
                    );
                }
            }
        }

        return new OverlayResult(
                List.copyOf(compositionByLocation.values()),
                List.copyOf(capturePlanByLocation.values())
        );
    }

    private List<NormativeEnvironmentSpec> resolveSpecs(String assetType,
                                                        String assetSubtype,
                                                        String refinedAssetSubtype,
                                                        NormativeMatrixResponse.RuleItem rule) {
        String normalizedType = normalize(assetType);
        String normalizedSubtype = normalize(refinedAssetSubtype != null && !refinedAssetSubtype.isBlank()
                ? refinedAssetSubtype
                : assetSubtype);
        String dimension = normalize(rule.dimension());

        if ("urbano".equals(normalizedType) && normalizedSubtype.contains("apartamento")) {
            return apartmentSpecs(dimension);
        }
        if ("urbano".equals(normalizedType) && (normalizedSubtype.contains("casa") || normalizedSubtype.contains("sobrado"))) {
            return houseSpecs(dimension);
        }
        if ("comercial".equals(normalizedType)) {
            return commercialSpecs(dimension);
        }
        if ("rural".equals(normalizedType)) {
            return ruralSpecs(dimension);
        }
        return genericSpecs(dimension);
    }

    private List<NormativeEnvironmentSpec> apartmentSpecs(String dimension) {
        return switch (dimension) {
            case "identificacao_externa" -> List.of(
                    spec("Rua", "Fachada", "Visao geral", "Numero do portao"),
                    spec("Rua", "Logradouro", "Visao geral", "Rua / via", "Calcada")
            );
            case "acesso_imovel" -> List.of(
                    spec("Rua", "Acesso ao imovel", "Visao geral", "Portao", "Fechadura", "Macaneta")
            );
            case "ambiente_social" -> List.of(
                    spec("Area interna", "Sala de estar", "Visao geral", "Piso", "Parede", "Teto"),
                    spec("Area interna", "Sala de jantar", "Visao geral", "Piso", "Parede", "Teto")
            );
            case "ambiente_molhado" -> List.of(
                    spec("Area interna", "Cozinha", "Visao geral", "Pia", "Bancada", "Piso", "Parede"),
                    spec("Area interna", "Banheiro", "Visao geral", "Box", "Chuveiro", "Vaso sanitario"),
                    spec("Area interna", "Lavanderia", "Visao geral", "Tanque", "Torneira")
            );
            case "conservacao_acabamento" -> List.of(
                    spec("Area interna", "Sala de estar", "Piso", "Parede", "Teto"),
                    spec("Area interna", "Cozinha", "Piso", "Parede", "Janela"),
                    spec("Area interna", "Banheiro", "Piso", "Parede", "Box")
            );
            default -> List.of();
        };
    }

    private List<NormativeEnvironmentSpec> houseSpecs(String dimension) {
        return switch (dimension) {
            case "identificacao_externa" -> List.of(
                    spec("Rua", "Fachada", "Visao geral", "Numero do portao", "Portao"),
                    spec("Rua", "Logradouro", "Visao geral", "Rua / via", "Calcada")
            );
            case "acesso_imovel" -> List.of(
                    spec("Rua", "Acesso ao imovel", "Visao geral", "Portao", "Fechadura")
            );
            case "ambiente_social" -> List.of(
                    spec("Area interna", "Sala de estar", "Visao geral", "Piso", "Parede"),
                    spec("Area externa", "Varanda", "Visao geral", "Piso")
            );
            case "ambiente_molhado" -> List.of(
                    spec("Area interna", "Cozinha", "Visao geral", "Pia", "Bancada"),
                    spec("Area interna", "Banheiro", "Visao geral", "Box", "Chuveiro"),
                    spec("Area interna", "Lavanderia", "Visao geral", "Tanque")
            );
            case "area_externa" -> List.of(
                    spec("Area externa", "Quintal", "Visao geral", "Piso", "Muro"),
                    spec("Area externa", "Garagem", "Visao geral", "Portao", "Piso")
            );
            default -> List.of();
        };
    }

    private List<NormativeEnvironmentSpec> commercialSpecs(String dimension) {
        return switch (dimension) {
            case "identificacao_externa" -> List.of(
                    spec("Rua", "Fachada", "Visao geral", "Numero do portao"),
                    spec("Rua", "Logradouro", "Visao geral", "Rua / via", "Calcada")
            );
            case "acesso_imovel" -> List.of(
                    spec("Rua", "Acesso ao imovel", "Visao geral", "Porta", "Fechadura")
            );
            case "area_operacional" -> List.of(
                    spec("Area interna", "Area de vendas", "Visao geral", "Piso", "Parede"),
                    spec("Area interna", "Sala principal", "Visao geral", "Piso", "Parede"),
                    spec("Area interna", "Estoque", "Visao geral")
            );
            case "conservacao_acabamento" -> List.of(
                    spec("Area interna", "Area de vendas", "Piso", "Parede", "Vitrine"),
                    spec("Area interna", "Sala principal", "Piso", "Parede", "Teto")
            );
            default -> List.of();
        };
    }

    private List<NormativeEnvironmentSpec> ruralSpecs(String dimension) {
        return switch (dimension) {
            case "identificacao_externa" -> List.of(
                    spec("Rua", "Entrada da propriedade", "Visao geral", "Porteira", "Cerca")
            );
            case "benfeitorias" -> List.of(
                    spec("Area externa", "Casa sede", "Visao geral"),
                    spec("Area externa", "Benfeitorias", "Visao geral")
            );
            case "entorno_uso" -> List.of(
                    spec("Area externa", "Acesso interno", "Visao geral", "Estrada interna"),
                    spec("Area externa", "Area externa", "Visao geral", "Solo", "Vegetacao")
            );
            default -> List.of();
        };
    }

    private List<NormativeEnvironmentSpec> genericSpecs(String dimension) {
        return switch (dimension) {
            case "identificacao_externa" -> List.of(
                    spec("Rua", "Fachada", "Visao geral"),
                    spec("Rua", "Logradouro", "Visao geral")
            );
            case "composicao_minima" -> List.of(
                    spec("Area interna", "Ambiente principal", "Visao geral"),
                    spec("Area externa", "Area de apoio", "Visao geral")
            );
            default -> List.of();
        };
    }

    private ExecutionPlanPayload.NormativeBinding toBinding(NormativeMatrixResponse.RuleItem rule) {
        return new ExecutionPlanPayload.NormativeBinding(
                rule.dimension(),
                rule.title(),
                rule.required(),
                "FINALIZATION".equalsIgnoreCase(rule.blockingStage()) && rule.required(),
                rule.minPhotos(),
                rule.maxPhotos(),
                rule.acceptedAlternatives() == null ? List.of() : List.copyOf(rule.acceptedAlternatives())
        );
    }

    private ExecutionPlanPayload.CameraEnvironmentProfile mergeEnvironment(
            ExecutionPlanPayload.CameraEnvironmentProfile left,
            ExecutionPlanPayload.CameraEnvironmentProfile right,
            ExecutionPlanPayload.NormativeBinding binding
    ) {
        Map<String, ExecutionPlanPayload.CameraElementProfile> mergedElements = new LinkedHashMap<>();
        if (left.elements() != null) {
            left.elements().forEach(item -> mergedElements.put(normalize(item.element()), item));
        }
        if (right.elements() != null) {
            for (ExecutionPlanPayload.CameraElementProfile item : right.elements()) {
                mergedElements.merge(normalize(item.element()), item, this::mergeElement);
            }
        }
        return new ExecutionPlanPayload.CameraEnvironmentProfile(
                blankTo(left.macroLocal(), right.macroLocal()),
                blankTo(left.photoLocation(), right.photoLocation()),
                left.required(),
                Math.max(left.minPhotos(), right.minPhotos()),
                List.copyOf(mergedElements.values()),
                resolveSource(left.source(), right.source()),
                mergeBindings(left.normativeBindings(), right.normativeBindings(), binding)
        );
    }

    private ExecutionPlanPayload.CapturePlanItem mergeCapturePlanItem(
            ExecutionPlanPayload.CapturePlanItem left,
            ExecutionPlanPayload.CapturePlanItem right,
            ExecutionPlanPayload.NormativeBinding binding
    ) {
        return new ExecutionPlanPayload.CapturePlanItem(
                blankTo(left.macroLocal(), right.macroLocal()),
                blankTo(left.environment(), right.environment()),
                blankTo(left.element(), right.element()),
                blankTo(left.material(), right.material()),
                blankTo(left.condition(), right.condition()),
                left.required(),
                Math.max(left.minPhotos(), right.minPhotos()),
                resolveSource(left.source(), right.source()),
                mergeBindings(left.normativeBindings(), right.normativeBindings(), binding)
        );
    }

    private ExecutionPlanPayload.CameraElementProfile mergeElement(
            ExecutionPlanPayload.CameraElementProfile left,
            ExecutionPlanPayload.CameraElementProfile right
    ) {
        Set<String> materials = new LinkedHashSet<>();
        if (left.materials() != null) {
            materials.addAll(left.materials());
        }
        if (right.materials() != null) {
            materials.addAll(right.materials());
        }
        Set<String> states = new LinkedHashSet<>();
        if (left.states() != null) {
            states.addAll(left.states());
        }
        if (right.states() != null) {
            states.addAll(right.states());
        }
        return new ExecutionPlanPayload.CameraElementProfile(
                left.element(),
                List.copyOf(materials),
                List.copyOf(states)
        );
    }

    private List<ExecutionPlanPayload.NormativeBinding> mergeBindings(
            List<ExecutionPlanPayload.NormativeBinding> left,
            List<ExecutionPlanPayload.NormativeBinding> right,
            ExecutionPlanPayload.NormativeBinding additional
    ) {
        Map<String, ExecutionPlanPayload.NormativeBinding> merged = new LinkedHashMap<>();
        if (left != null) {
            for (ExecutionPlanPayload.NormativeBinding item : left) {
                merged.put(normalize(item.dimension()), item);
            }
        }
        if (right != null) {
            for (ExecutionPlanPayload.NormativeBinding item : right) {
                merged.put(normalize(item.dimension()), item);
            }
        }
        if (additional != null) {
            merged.put(normalize(additional.dimension()), additional);
        }
        return List.copyOf(merged.values());
    }

    private String resolveSource(String left, String right) {
        Set<String> values = new LinkedHashSet<>();
        if (left != null && !left.isBlank()) {
            values.add(left);
        }
        if (right != null && !right.isBlank()) {
            values.add(right);
        }
        if (values.contains("COMPOSITION") && values.contains("NORMATIVE")) {
            return "HYBRID";
        }
        if (values.contains("HYBRID")) {
            return "HYBRID";
        }
        if (values.contains("NORMATIVE")) {
            return "NORMATIVE";
        }
        return "COMPOSITION";
    }

    private NormativeEnvironmentSpec spec(String macroLocal, String photoLocation, String... elementNames) {
        List<ExecutionPlanPayload.CameraElementProfile> elements = new ArrayList<>();
        for (String elementName : elementNames) {
            elements.add(new ExecutionPlanPayload.CameraElementProfile(
                    elementName,
                    List.of(),
                    List.of("Novo", "Bom", "Regular", "Ruim", "Pessimo")
            ));
        }
        return new NormativeEnvironmentSpec(macroLocal, photoLocation, List.copyOf(elements));
    }

    private String normalize(String value) {
        return value == null ? "" : value.trim().toLowerCase(Locale.ROOT);
    }

    private String blankTo(String preferred, String fallback) {
        return preferred == null || preferred.isBlank() ? fallback : preferred;
    }

    public record OverlayResult(
            List<ExecutionPlanPayload.CameraEnvironmentProfile> compositionProfiles,
            List<ExecutionPlanPayload.CapturePlanItem> capturePlan
    ) {
    }

    private record NormativeEnvironmentSpec(
            String macroLocal,
            String photoLocation,
            List<ExecutionPlanPayload.CameraElementProfile> elements
    ) {
        private ExecutionPlanPayload.CameraEnvironmentProfile toEnvironmentProfile(ExecutionPlanPayload.NormativeBinding binding) {
            return new ExecutionPlanPayload.CameraEnvironmentProfile(
                    macroLocal,
                    photoLocation,
                    false,
                    1,
                    elements,
                    "NORMATIVE",
                    List.of(binding)
            );
        }

        private ExecutionPlanPayload.CapturePlanItem toCapturePlanItem(ExecutionPlanPayload.NormativeBinding binding) {
            String element = elements.isEmpty() ? "Visao geral" : elements.getFirst().element();
            return new ExecutionPlanPayload.CapturePlanItem(
                    macroLocal,
                    photoLocation,
                    element,
                    null,
                    null,
                    false,
                    1,
                    "NORMATIVE",
                    List.of(binding)
            );
        }
    }
}
