package com.appbackoffice.api.intelligence.service;

import com.appbackoffice.api.intelligence.model.ExecutionPlanPayload;
import com.appbackoffice.api.intelligence.port.ResearchProviderResponse;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

@Component
public class OperationalCaptureCatalog {

    public List<String> referenceCandidateSubtypes(String assetType, String assetSubtype) {
        if (isUndefinedSubtype(assetSubtype) && "Urbano".equalsIgnoreCase(assetType)) {
            return List.of("Casa", "Sobrado", "Apartamento", "Terreno");
        }
        if ("Apartamento".equalsIgnoreCase(assetSubtype)) {
            return List.of("Apartamento", "Apartamento padrao", "Apartamento alto padrao", "Duplex", "Triplex");
        }
        if ("Casa".equalsIgnoreCase(assetSubtype)) {
            return List.of("Casa", "Casa geminada", "Sobrado");
        }
        if ("Sobrado".equalsIgnoreCase(assetSubtype)) {
            return List.of("Sobrado", "Casa", "Casa geminada");
        }
        if ("Galpao".equalsIgnoreCase(assetSubtype)) {
            return List.of("Galpao", "Galpao logistico", "Galpao industrial", "Deposito");
        }
        if ("Loja".equalsIgnoreCase(assetSubtype) || "Sala comercial".equalsIgnoreCase(assetSubtype)) {
            return List.of(assetSubtype, "Loja", "Sala comercial", "Escritorio", "Consultorio");
        }
        if ("Sitio".equalsIgnoreCase(assetSubtype) || "Chacara".equalsIgnoreCase(assetSubtype) || "Fazenda".equalsIgnoreCase(assetSubtype)) {
            return List.of("Sitio", "Chacara", "Fazenda");
        }
        if ("Terreno".equalsIgnoreCase(assetSubtype)) {
            return List.of("Terreno", "Lote");
        }
        if (assetSubtype == null || assetSubtype.isBlank()) {
            return List.of(assetType);
        }
        return List.of(assetSubtype, assetType);
    }

    public List<String> defaultPhotoLocations(String assetType, String assetSubtype) {
        return referenceProfiles(assetType, assetSubtype).stream()
                .map(ExecutionPlanPayload.CameraEnvironmentProfile::photoLocation)
                .toList();
    }

    public List<ExecutionPlanPayload.CameraEnvironmentProfile> referenceCompositionProfiles(String assetType, String assetSubtype) {
        return referenceProfiles(assetType, assetSubtype);
    }

    public List<String> enrichWithCompositionSignals(List<String> baseLocations,
                                                     ResearchFactResolver resolver,
                                                     ResearchProviderResponse response) {
        Set<String> enriched = new LinkedHashSet<>(baseLocations);
        maybeAdd(enriched, resolver, response, "piscina", "Piscina");
        maybeAdd(enriched, resolver, response, "academia", "Academia");
        maybeAdd(enriched, resolver, response, "playground", "Playground");
        maybeAdd(enriched, resolver, response, "churrasqueira", "Churrasqueira");
        maybeAdd(enriched, resolver, response, "salao de festas", "Salao de festas");
        maybeAdd(enriched, resolver, response, "cozinha", "Cozinha");
        maybeAdd(enriched, resolver, response, "sala de jantar", "Sala de jantar");
        maybeAdd(enriched, resolver, response, "sala de estar", "Sala de estar");
        maybeAdd(enriched, resolver, response, "dormitorio", "Dormitorio");
        maybeAdd(enriched, resolver, response, "suite", "Suite");
        maybeAdd(enriched, resolver, response, "banheiro", "Banheiro");
        maybeAdd(enriched, resolver, response, "lavanderia", "Lavanderia");
        maybeAdd(enriched, resolver, response, "varanda", "Varanda");
        maybeAdd(enriched, resolver, response, "vaga", "Vaga de garagem");
        return List.copyOf(enriched);
    }

    public List<ExecutionPlanPayload.CameraEnvironmentProfile> buildCompositionProfiles(String assetType,
                                                                                        String assetSubtype,
                                                                                        List<String> photoLocations) {
        Map<String, ExecutionPlanPayload.CameraEnvironmentProfile> reference = new LinkedHashMap<>();
        for (ExecutionPlanPayload.CameraEnvironmentProfile item : referenceProfiles(assetType, assetSubtype)) {
            reference.put(item.photoLocation(), item);
        }

        List<ExecutionPlanPayload.CameraEnvironmentProfile> resolved = new ArrayList<>();
        for (String location : photoLocations) {
            if (location == null || location.isBlank()) {
                continue;
            }
            ExecutionPlanPayload.CameraEnvironmentProfile profile = reference.get(location);
            if (profile != null) {
                resolved.add(profile);
                continue;
            }
            resolved.add(new ExecutionPlanPayload.CameraEnvironmentProfile(
                    contextForLocation(location, assetSubtype),
                    location,
                    false,
                    1,
                    List.of(defaultOverviewElement()),
                    "COMPOSITION",
                    List.of()
            ));
        }
        return List.copyOf(resolved);
    }

    public List<String> resolveAvailableContexts(List<ExecutionPlanPayload.CameraEnvironmentProfile> compositionProfiles) {
        Set<String> contexts = new LinkedHashSet<>();
        if (compositionProfiles != null) {
            for (ExecutionPlanPayload.CameraEnvironmentProfile profile : compositionProfiles) {
                String macroLocal = normalizeContext(profile.macroLocal());
                if (!macroLocal.isBlank()) {
                    contexts.add(macroLocal);
                }
            }
        }
        if (contexts.isEmpty()) {
            contexts.add("Rua");
            contexts.add("Area externa");
            contexts.add("Area interna");
        }
        return List.copyOf(contexts);
    }

    public List<ExecutionPlanPayload.CapturePlanItem> buildCapturePlan(List<ExecutionPlanPayload.CameraEnvironmentProfile> compositionProfiles,
                                                                       String initialContext) {
        Set<ExecutionPlanPayload.CapturePlanItem> items = new LinkedHashSet<>();
        if (compositionProfiles.isEmpty()) {
            items.add(new ExecutionPlanPayload.CapturePlanItem(
                    normalizeContext(initialContext),
                    "Fachada",
                    "Visao geral",
                    null,
                    null,
                    true,
                    1,
                    "COMPOSITION",
                    List.of()
            ));
            return List.copyOf(items);
        }
        for (ExecutionPlanPayload.CameraEnvironmentProfile environmentProfile : compositionProfiles) {
            ExecutionPlanPayload.CameraElementProfile firstElement = environmentProfile.elements().isEmpty()
                    ? defaultOverviewElement()
                    : environmentProfile.elements().getFirst();
            items.add(new ExecutionPlanPayload.CapturePlanItem(
                    normalizeContext(environmentProfile.macroLocal()),
                    environmentProfile.photoLocation(),
                    firstElement.element(),
                    firstElement.materials().isEmpty() ? null : firstElement.materials().getFirst(),
                    firstElement.states().isEmpty() ? null : firstElement.states().getFirst(),
                    environmentProfile.required(),
                    environmentProfile.minPhotos(),
                    environmentProfile.source(),
                    environmentProfile.normativeBindings() == null ? List.of() : environmentProfile.normativeBindings()
            ));
        }
        return List.copyOf(items);
    }

    public String resolveInitialContext(String assetType,
                                        String assetSubtype,
                                        List<String> photoLocations,
                                        List<ExecutionPlanPayload.CameraEnvironmentProfile> compositionProfiles) {
        if (compositionProfiles != null && !compositionProfiles.isEmpty()) {
            for (ExecutionPlanPayload.CameraEnvironmentProfile profile : compositionProfiles) {
                String context = normalizeContext(profile.macroLocal());
                if (!context.isBlank()) {
                    return context;
                }
            }
        }

        if (photoLocations != null && !photoLocations.isEmpty()) {
            for (String location : photoLocations) {
                if (location == null || location.isBlank()) {
                    continue;
                }
                return contextForLocation(location, assetSubtype);
            }
        }

        List<ExecutionPlanPayload.CameraEnvironmentProfile> references = referenceProfiles(assetType, assetSubtype);
        if (!references.isEmpty()) {
            return normalizeContext(references.getFirst().macroLocal());
        }

        if ("Rural".equalsIgnoreCase(assetType)) {
            return "Area externa";
        }
        return "Rua";
    }

    private List<ExecutionPlanPayload.CameraEnvironmentProfile> referenceProfiles(String assetType, String assetSubtype) {
        if (isUndefinedSubtype(assetSubtype) && "Urbano".equalsIgnoreCase(assetType)) {
            return List.of(
                    environment("Rua", "Fachada", true, 1, element("Visao geral"), element("Numero do portao"), element("Portao", "Metal", "Madeira")),
                    environment("Rua", "Logradouro", true, 1, element("Visao geral"), element("Rua / via", "Concreto", "Pedra"), element("Calcada", "Concreto", "Ceramica")),
                    environment("Rua", "Acesso ao imovel", true, 1, element("Visao geral"), element("Portao", "Metal", "Madeira"), element("Fechadura", "Metal"))
            );
        }
        if ("Apartamento".equalsIgnoreCase(assetSubtype)) {
            return List.of(
                    environment("Rua", "Fachada", true, 1, element("Visao geral"), element("Numero do portao"), element("Portao", "Metal", "Madeira"), element("Fachada interna / area comum")),
                    environment("Rua", "Acesso ao imovel", true, 1, element("Visao geral"), element("Portao", "Metal", "Madeira"), element("Fechadura", "Metal"), element("Macaneta", "Metal")),
                    environment("Area interna", "Cozinha", false, 1, element("Visao geral"), element("Janela", "Metal", "Vidro", "Aluminio"), element("Piso", "Ceramica", "Porcelanato", "Pedra"), element("Parede", "Pintura", "Azulejo", "Revestimento"), element("Bancada", "Pedra", "Porcelanato"), element("Pia", "Inox", "Pedra"), element("Torneira", "Metal", "Inox")),
                    environment("Area interna", "Sala de jantar", false, 1, element("Visao geral"), element("Piso", "Ceramica", "Porcelanato", "Madeira"), element("Parede", "Pintura"), element("Teto", "Pintura", "Forro")),
                    environment("Area interna", "Sala de estar", false, 1, element("Visao geral"), element("Porta", "Madeira", "Metal"), element("Janela", "Vidro", "Aluminio"), element("Piso", "Ceramica", "Porcelanato", "Madeira"), element("Parede", "Pintura"), element("Teto", "Pintura", "Forro")),
                    environment("Area interna", "Dormitorio", false, 1, element("Visao geral"), element("Porta", "Madeira", "Metal"), element("Janela", "Vidro", "Aluminio"), element("Piso", "Ceramica", "Porcelanato", "Madeira"), element("Parede", "Pintura"), element("Teto", "Pintura", "Forro")),
                    environment("Area interna", "Suite", false, 1, element("Visao geral"), element("Porta", "Madeira", "Metal"), element("Janela", "Vidro", "Aluminio"), element("Piso", "Ceramica", "Porcelanato", "Madeira"), element("Parede", "Pintura"), element("Teto", "Pintura", "Forro")),
                    environment("Area interna", "Banheiro", false, 1, element("Visao geral"), element("Piso", "Ceramica", "Porcelanato", "Pedra"), element("Parede", "Azulejo", "Revestimento", "Pintura"), element("Box", "Vidro", "Aluminio"), element("Chuveiro", "Metal", "Inox"), element("Vaso sanitario"), element("Caixa de descarga"), element("Torneira", "Metal", "Inox")),
                    environment("Area interna", "Lavanderia", false, 1, element("Visao geral"), element("Tanque", "Inox", "Ceramica"), element("Torneira", "Metal", "Inox"), element("Piso", "Ceramica", "Porcelanato"), element("Parede", "Pintura", "Azulejo")),
                    environment("Area externa", "Varanda", false, 1, element("Visao geral"), element("Guarda-corpo", "Metal", "Vidro"), element("Corrimao", "Metal"), element("Piso", "Ceramica", "Porcelanato", "Pedra")),
                    environment("Area externa", "Vaga de garagem", false, 1, element("Visao geral"), element("Vaga demarcada"), element("Piso", "Concreto", "Pintura")),
                    environment("Area externa", "Academia", false, 1, element("Visao geral"), element("Equipamento de lazer")),
                    environment("Area externa", "Piscina", false, 1, element("Visao geral"), element("Guarda-corpo", "Metal", "Vidro"), element("Piso", "Pedra", "Ceramica")),
                    environment("Area externa", "Salao de festas", false, 1, element("Visao geral"), element("Piso", "Ceramica", "Porcelanato"), element("Parede", "Pintura")),
                    environment("Area externa", "Churrasqueira", false, 1, element("Visao geral"), element("Revestimento", "Ceramica", "Pedra"), element("Piso", "Ceramica", "Porcelanato")),
                    environment("Area externa", "Playground", false, 1, element("Visao geral"), element("Equipamento de lazer"))
            );
        }
        if ("Casa".equalsIgnoreCase(assetSubtype) || "Sobrado".equalsIgnoreCase(assetSubtype)) {
            return List.of(
                    environment("Rua", "Fachada", true, 1, element("Visao geral"), element("Numero do portao"), element("Portao", "Metal", "Madeira"), element("Janela", "Vidro", "Aluminio")),
                    environment("Rua", "Acesso ao imovel", true, 1, element("Visao geral"), element("Portao", "Metal", "Madeira"), element("Fechadura", "Metal")),
                    environment("Area interna", "Sala de estar", false, 1, element("Visao geral"), element("Porta", "Madeira", "Metal"), element("Piso", "Ceramica", "Porcelanato", "Madeira"), element("Parede", "Pintura")),
                    environment("Area interna", "Cozinha", false, 1, element("Visao geral"), element("Pia", "Inox", "Pedra"), element("Bancada", "Pedra", "Porcelanato"), element("Piso", "Ceramica", "Porcelanato")),
                    environment("Area interna", "Dormitorio", false, 1, element("Visao geral"), element("Janela", "Vidro", "Aluminio"), element("Piso", "Ceramica", "Porcelanato", "Madeira")),
                    environment("Area interna", "Banheiro", false, 1, element("Visao geral"), element("Box", "Vidro", "Aluminio"), element("Chuveiro", "Metal", "Inox"), element("Vaso sanitario")),
                    environment("Area externa", "Garagem", false, 1, element("Visao geral"), element("Portao", "Metal", "Madeira"), element("Piso", "Concreto", "Ceramica")),
                    environment("Area externa", "Quintal", false, 1, element("Visao geral"), element("Piso", "Concreto", "Pedra"), element("Muro", "Pintura", "Concreto"))
            );
        }
        if ("Loja".equalsIgnoreCase(assetSubtype) || "Sala comercial".equalsIgnoreCase(assetSubtype)) {
            return List.of(
                    environment("Rua", "Fachada", true, 1, element("Visao geral"), element("Porta", "Vidro", "Metal"), element("Janela", "Vidro", "Aluminio")),
                    environment("Rua", "Acesso ao imovel", true, 1, element("Visao geral"), element("Porta", "Vidro", "Metal"), element("Fechadura", "Metal")),
                    environment("Area interna", "Recepcao", false, 1, element("Visao geral"), element("Balcao", "Madeira", "Pedra"), element("Piso", "Ceramica", "Porcelanato")),
                    environment("Area interna", "Area de vendas", false, 1, element("Visao geral"), element("Piso", "Ceramica", "Porcelanato"), element("Parede", "Pintura"), element("Vitrine", "Vidro", "Aluminio")),
                    environment("Area interna", "Sala principal", false, 1, element("Visao geral"), element("Piso", "Ceramica", "Porcelanato"), element("Parede", "Pintura"), element("Teto", "Pintura", "Forro")),
                    environment("Area interna", "Copa", false, 1, element("Visao geral"), element("Bancada", "Pedra", "Porcelanato"), element("Pia", "Inox", "Pedra")),
                    environment("Area interna", "Banheiro", false, 1, element("Visao geral"), element("Vaso sanitario"), element("Pia", "Inox", "Pedra")),
                    environment("Area interna", "Estoque", false, 1, element("Visao geral"), element("Prateleira", "Metal", "Madeira"))
            );
        }
        if ("Galpao".equalsIgnoreCase(assetSubtype)) {
            return List.of(
                    environment("Rua", "Fachada", true, 1, element("Visao geral"), element("Portao", "Metal"), element("Numero do portao")),
                    environment("Rua", "Acesso ao imovel", true, 1, element("Visao geral"), element("Portao", "Metal"), element("Fechadura", "Metal")),
                    environment("Area externa", "Patio de manobra", false, 1, element("Visao geral"), element("Piso", "Concreto"), element("Portao", "Metal")),
                    environment("Area externa", "Doca", false, 1, element("Visao geral"), element("Portao", "Metal"), element("Piso", "Concreto")),
                    environment("Area interna", "Area de armazenagem", false, 1, element("Visao geral"), element("Piso", "Concreto"), element("Cobertura", "Metal"), element("Pilar", "Concreto", "Metal")),
                    environment("Area interna", "Area administrativa", false, 1, element("Visao geral"), element("Piso", "Ceramica", "Porcelanato"), element("Parede", "Pintura")),
                    environment("Area interna", "Mezanino", false, 1, element("Visao geral"), element("Corrimao", "Metal"), element("Piso", "Metal", "Concreto")),
                    environment("Area interna", "Vestiario", false, 1, element("Visao geral"), element("Piso", "Ceramica"), element("Parede", "Azulejo", "Pintura"))
            );
        }
        if ("Sitio".equalsIgnoreCase(assetSubtype) || "Chacara".equalsIgnoreCase(assetSubtype) || "Fazenda".equalsIgnoreCase(assetSubtype)) {
            return List.of(
                    environment("Rua", "Entrada da propriedade", true, 1, element("Visao geral"), element("Porteira", "Madeira", "Metal"), element("Cerca", "Madeira", "Metal")),
                    environment("Area externa", "Area externa", false, 1, element("Visao geral"), element("Solo", "Concreto", "Pedra"), element("Vegetacao")),
                    environment("Area externa", "Casa sede", false, 1, element("Visao geral"), element("Porta", "Madeira", "Metal"), element("Janela", "Vidro", "Aluminio")),
                    environment("Area externa", "Benfeitorias", false, 1, element("Visao geral"), element("Cobertura"), element("Porta", "Madeira", "Metal")),
                    environment("Area externa", "Acesso interno", false, 1, element("Visao geral"), element("Estrada interna", "Concreto", "Pedra"))
            );
        }
        if ("Terreno".equalsIgnoreCase(assetSubtype)) {
            return List.of(
                    environment("Rua", "Fachada", true, 1, element("Visao geral")),
                    environment("Rua", "Logradouro", true, 1, element("Visao geral"), element("Rua / via", "Concreto", "Pedra"), element("Calcada", "Concreto", "Ceramica")),
                    environment("Rua", "Perimetro", false, 1, element("Visao geral")),
                    environment("Rua", "Entorno", false, 1, element("Visao geral"))
            );
        }
        return List.of(
                environment("Rua", "Fachada", true, 1, element("Visao geral")),
                environment("Rua", "Logradouro", true, 1, element("Visao geral")),
                environment("Rua", "Acesso ao imovel", true, 1, element("Visao geral"), element("Portao", "Metal", "Madeira"))
        );
    }

    private ExecutionPlanPayload.CameraEnvironmentProfile environment(String macroLocal,
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

    private ExecutionPlanPayload.CameraElementProfile element(String name, String... materials) {
        return new ExecutionPlanPayload.CameraElementProfile(
                name,
                List.of(materials),
                List.of("Novo", "Bom", "Regular", "Ruim", "Pessimo")
        );
    }

    private ExecutionPlanPayload.CameraElementProfile defaultOverviewElement() {
        return new ExecutionPlanPayload.CameraElementProfile(
                "Visao geral",
                List.of(),
                List.of("Novo", "Bom", "Regular", "Ruim", "Pessimo")
        );
    }

    private String contextForLocation(String location, String assetSubtype) {
        String normalized = location.trim().toLowerCase();
        if (normalized.contains("fachada") || normalized.contains("logradouro") || normalized.contains("acesso")) {
            return "Rua";
        }
        if (normalized.contains("garagem") || normalized.contains("playground") || normalized.contains("piscina")
                || normalized.contains("churrasqueira") || normalized.contains("academia")
                || normalized.contains("salao") || normalized.contains("varanda")
                || normalized.contains("vaga")) {
            return "Area externa";
        }
        if ("Terreno".equalsIgnoreCase(assetSubtype) || normalized.contains("perimetro") || normalized.contains("entorno")) {
            return "Rua";
        }
        return "Area interna";
    }

    private String normalizeContext(String value) {
        return value == null || value.isBlank() ? "Rua" : value;
    }

    private void maybeAdd(Set<String> target,
                          ResearchFactResolver resolver,
                          ResearchProviderResponse response,
                          String fragment,
                          String value) {
        if (resolver.containsText(response, fragment)) {
            target.add(value);
        }
    }

    private boolean isUndefinedSubtype(String assetSubtype) {
        if (assetSubtype == null || assetSubtype.isBlank()) {
            return true;
        }
        String normalized = assetSubtype.trim().toLowerCase();
        return normalized.equals("indefinido") || normalized.equals("imovel");
    }
}
