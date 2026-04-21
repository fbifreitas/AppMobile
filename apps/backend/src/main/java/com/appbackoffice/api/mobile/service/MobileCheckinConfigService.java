package com.appbackoffice.api.mobile.service;

import com.appbackoffice.api.config.ConfigPackageService;
import com.appbackoffice.api.config.dto.ConfigCheckinSectionRuleDto;
import com.appbackoffice.api.config.dto.ConfigPackageResponse;
import com.appbackoffice.api.config.dto.ConfigResolveResponse;
import com.appbackoffice.api.config.dto.ConfigRulesDto;
import com.appbackoffice.api.intelligence.service.CaptureGatePolicyService;
import com.appbackoffice.api.intelligence.service.NormativeMatrixService;
import com.appbackoffice.api.mobile.dto.CheckinConfigResponse;
import com.appbackoffice.api.mobile.entity.CheckinSectionEntity;
import com.appbackoffice.api.mobile.repository.CheckinSectionRepository;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
public class MobileCheckinConfigService {

    private final ConfigPackageService configPackageService;
    private final CheckinSectionRepository checkinSectionRepository;
    private final ObjectMapper objectMapper;
    private final CaptureGatePolicyService captureGatePolicyService;
    private final NormativeMatrixService normativeMatrixService;

    public MobileCheckinConfigService(ConfigPackageService configPackageService,
                                      CheckinSectionRepository checkinSectionRepository,
                                      ObjectMapper objectMapper,
                                      CaptureGatePolicyService captureGatePolicyService,
                                      NormativeMatrixService normativeMatrixService) {
        this.configPackageService = configPackageService;
        this.checkinSectionRepository = checkinSectionRepository;
        this.objectMapper = objectMapper;
        this.captureGatePolicyService = captureGatePolicyService;
        this.normativeMatrixService = normativeMatrixService;
    }

    public CheckinConfigResponse resolve(String tenantId, String actorId, String assetType) {
        ConfigResolveResponse resolveResponse = configPackageService.resolveForMobile(tenantId, actorId, null);
        ConfigRulesDto effective = resolveResponse.result().effective();

        List<CheckinConfigResponse.CheckinSectionDto> sections = resolveSections(tenantId, assetType, effective);
        Map<String, Object> step1 = buildStep1(tenantId, effective, assetType);
        Map<String, Object> step2 = buildStep2(tenantId, effective, sections);
        Map<String, Object> camera = buildCamera(effective);
        Instant publishedAt = resolvePublishedAt(resolveResponse.result().appliedPackages(), tenantId, sections.isEmpty());
        Instant publishedAtForResponse = publishedAt.equals(Instant.EPOCH) ? Instant.now() : publishedAt;

        return new CheckinConfigResponse(
                buildVersion(resolveResponse.result().appliedPackages(), publishedAt),
                publishedAtForResponse.toString(),
                resolveResponse.result().appliedPackages().stream().map(ConfigPackageResponse::id).toList(),
                step1,
                step2,
                camera,
                sections,
                buildNotes(resolveResponse.result().appliedPackages())
        );
    }

    private Map<String, Object> buildStep1(String tenantId, ConfigRulesDto effective, String assetType) {
        Map<String, Object> step1 = mutableCopy(effective != null ? effective.step1() : null);
        if (step1.isEmpty()) {
            step1.put("tipos", List.of("Urbano", "Rural", "Comercial", "Industrial"));

            Map<String, Object> defaults = new LinkedHashMap<>();
            defaults.put("Urbano", List.of("Apartamento", "Casa", "Sobrado", "Terreno"));
            defaults.put("Rural", List.of("Sitio", "Chacara", "Fazenda"));
            defaults.put("Comercial", List.of("Loja", "Sala comercial", "Galpao"));
            defaults.put("Industrial", List.of("Fabrica", "Armazem", "Planta industrial"));
            step1.put("subtiposPorTipo", defaults);
            step1.put("contextos", List.of("Rua", "Area externa", "Area interna"));
        }
        normalizeStep1ContextLevel(step1);
        aliasStep1Fields(step1);
        step1.put("captureGatePolicy", captureGatePolicyService.resolve(tenantId));
        if (assetType != null && !assetType.isBlank()) {
            step1.put("requestedTipoImovel", assetType);
            step1.put("requestedAssetType", assetType);
        }
        return step1;
    }

    @SuppressWarnings("unchecked")
    private void normalizeStep1ContextLevel(Map<String, Object> step1) {
        Object rawContexts = step1.get("contextos");
        if (!(rawContexts instanceof List<?> contextList) || contextList.isEmpty()) {
            return;
        }

        List<String> contexts = contextList.stream()
                .map(value -> value != null ? value.toString().trim() : "")
                .filter(value -> !value.isEmpty())
                .collect(java.util.stream.Collectors.collectingAndThen(
                        java.util.stream.Collectors.toCollection(LinkedHashSet::new),
                        ArrayList::new
                ));

        if (contexts.isEmpty()) {
            return;
        }

        Object rawLevels = step1.get("levels");
        if (!(rawLevels instanceof List<?> levels)) {
            return;
        }

        for (Object levelItem : levels) {
            if (!(levelItem instanceof Map<?, ?> levelMap)) {
                continue;
            }
            Object rawId = levelMap.get("id");
            String levelId = rawId != null ? rawId.toString().trim().toLowerCase() : "";
            if (!"contexto".equals(levelId) && !"macrolocal".equals(levelId) && !"entrypoint".equals(levelId)) {
                continue;
            }
            ((Map<String, Object>) levelMap).put("options", contexts);
        }
    }

    @SuppressWarnings("unchecked")
    private void aliasStep1Fields(Map<String, Object> step1) {
        Object assetTypes = step1.get("tipos");
        if (assetTypes instanceof List<?>) {
            step1.putIfAbsent("assetTypes", assetTypes);
        }

        Object assetSubtypes = step1.get("subtiposPorTipo");
        if (assetSubtypes instanceof Map<?, ?>) {
            step1.putIfAbsent("assetSubtypesByType", assetSubtypes);
        }

        Object entryPoints = step1.get("contextos");
        if (entryPoints instanceof List<?>) {
            step1.putIfAbsent("entryPoints", entryPoints);
        }

        Object rawLevels = step1.get("levels");
        if (!(rawLevels instanceof List<?> levels)) {
            return;
        }

        for (Object levelItem : levels) {
            if (!(levelItem instanceof Map<?, ?> levelMap)) {
                continue;
            }
            Map<String, Object> mutableLevel = (Map<String, Object>) levelMap;
            Object rawId = mutableLevel.get("id");
            String levelId = rawId != null ? rawId.toString().trim() : "";
            if ("contexto".equalsIgnoreCase(levelId) || "macrolocal".equalsIgnoreCase(levelId)) {
                mutableLevel.putIfAbsent("canonicalId", "entryPoint");
            }
        }
    }

    private Map<String, Object> buildStep2(
            String tenantId,
            ConfigRulesDto effective,
            List<CheckinConfigResponse.CheckinSectionDto> sections
    ) {
        Map<String, Object> step2 = mutableCopy(effective != null ? effective.step2() : null);
        step2.put("photoPolicy", Map.of(
                "min", effective != null && effective.cameraMinPhotos() != null ? effective.cameraMinPhotos() : 1,
                "max", effective != null && effective.cameraMaxPhotos() != null ? effective.cameraMaxPhotos() : 5
        ));
        step2.put("featureFlags", Map.of(
                "enableVoiceCommands", effective != null && effective.enableVoiceCommands() != null ? effective.enableVoiceCommands() : true,
                "requireBiometric", effective != null && effective.requireBiometric() != null ? effective.requireBiometric() : false
        ));

        if ((effective != null && effective.theme() != null) || (effective != null && effective.appUpdateChannel() != null)) {
            Map<String, Object> presentation = new LinkedHashMap<>();
            presentation.put("theme", effective.theme());
            presentation.put("appUpdateChannel", effective.appUpdateChannel());
            step2.put("presentation", presentation);
        }

        Object byTipo = step2.get("byTipo");
        if (byTipo instanceof Map<?, ?> byTypeMap) {
            step2.putIfAbsent("byAssetType", byTypeMap);
        }
        step2.putIfAbsent("camposFotos", defaultLegacyPhotoFields(sections));
        step2.putIfAbsent("gruposOpcoes", new ArrayList<>());
        step2.putIfAbsent("photoFields", step2.get("camposFotos"));
        step2.putIfAbsent("optionGroups", step2.get("gruposOpcoes"));
        step2.put("normativeMatrix", normativeMatrixService.resolve(tenantId));
        return step2;
    }

    private Map<String, Object> buildCamera(ConfigRulesDto effective) {
        return mutableCopy(effective != null ? effective.camera() : null);
    }

    private List<String> defaultLegacyPhotoFields(List<CheckinConfigResponse.CheckinSectionDto> sections) {
        if (sections == null || sections.isEmpty()) {
            return List.of("fachada", "logradouro");
        }
        return sections.stream().map(CheckinConfigResponse.CheckinSectionDto::key).toList();
    }

    @SuppressWarnings("unchecked")
    private Map<String, Object> mutableCopy(Map<String, Object> source) {
        if (source == null || source.isEmpty()) {
            return new LinkedHashMap<>();
        }
        Map<String, Object> copy = new LinkedHashMap<>();
        for (Map.Entry<String, Object> entry : source.entrySet()) {
            Object value = entry.getValue();
            if (value instanceof Map<?, ?> mapValue) {
                copy.put(entry.getKey(), mutableCopy((Map<String, Object>) mapValue));
            } else if (value instanceof List<?> listValue) {
                copy.put(entry.getKey(), new ArrayList<>(listValue));
            } else {
                copy.put(entry.getKey(), value);
            }
        }
        return copy;
    }

    private String buildVersion(List<ConfigPackageResponse> appliedPackages, Instant publishedAt) {
        if (appliedPackages.isEmpty() && publishedAt.equals(Instant.EPOCH)) {
            return "v1-default";
        }
        return "cfg-" + publishedAt.toEpochMilli();
    }

    private List<String> buildNotes(List<ConfigPackageResponse> appliedPackages) {
        if (appliedPackages.isEmpty()) {
            return List.of(
                    "Compatibilidade v1: campos existentes nÃ£o serÃ£o removidos/renomeados sem nova major.",
                    "ConfiguraÃ§Ã£o efetiva padrÃ£o aplicada: nenhum pacote ativo encontrado para o tenant/usuÃ¡rio.",
                    "Tenant e correlationId sÃ£o obrigatÃ³rios para rastreabilidade ponta a ponta."
            );
        }

        String appliedIds = appliedPackages.stream()
                .map(ConfigPackageResponse::id)
                .toList()
                .toString();

        return List.of(
                "Compatibilidade v1: campos existentes nÃ£o serÃ£o removidos/renomeados sem nova major.",
                "ConfiguraÃ§Ã£o efetiva derivada de pacotes ativos: " + appliedIds,
                "Tenant e correlationId sÃ£o obrigatÃ³rios para rastreabilidade ponta a ponta."
        );
    }

        private List<CheckinConfigResponse.CheckinSectionDto> resolveSections(
                String tenantId,
                String assetType,
                ConfigRulesDto effective
        ) {
        List<ConfigCheckinSectionRuleDto> packageSections = resolveSectionsFromRules(effective, assetType);
        if (!packageSections.isEmpty()) {
            return packageSections.stream()
                    .map(section -> new CheckinConfigResponse.CheckinSectionDto(
                            section.sectionKey(),
                            section.sectionLabel(),
                            section.mandatory() != null && section.mandatory(),
                            new CheckinConfigResponse.PhotoPolicyDto(
                                    section.photoMin() != null ? section.photoMin() : 1,
                                    section.photoMax() != null ? section.photoMax() : 5
                            ),
                            section.desiredItems() != null ? section.desiredItems() : List.of()
                    ))
                    .toList();
        }

        List<CheckinSectionEntity> all = checkinSectionRepository
            .findByTenantIdAndActiveTrueOrderBySortOrderAscUpdatedAtAsc(tenantId);

        List<CheckinSectionEntity> matched = all.stream()
                .filter(section -> sectionMatchesAssetType(section, assetType))
            .toList();

        if (matched.isEmpty()) {
            return defaultSections();
        }

        return matched.stream()
            .map(section -> new CheckinConfigResponse.CheckinSectionDto(
                section.getSectionKey(),
                section.getSectionLabel(),
                section.isMandatory(),
                new CheckinConfigResponse.PhotoPolicyDto(
                    section.getPhotoMin() != null ? section.getPhotoMin() : 1,
                    section.getPhotoMax() != null ? section.getPhotoMax() : 5
                ),
                parseDesiredItems(section.getDesiredItemsJson())
            ))
            .toList();
        }

        private List<ConfigCheckinSectionRuleDto> resolveSectionsFromRules(
                ConfigRulesDto effective,
                String assetType
        ) {
        if (effective == null || effective.checkinSections() == null || effective.checkinSections().isEmpty()) {
            return List.of();
        }

        return effective.checkinSections()
                .stream()
                .filter(section -> sectionMatchesAssetType(section.assetType(), assetType))
                .sorted((a, b) -> Integer.compare(
                        a.sortOrder() != null ? a.sortOrder() : Integer.MAX_VALUE,
                        b.sortOrder() != null ? b.sortOrder() : Integer.MAX_VALUE
                ))
                .toList();
        }

        private Instant resolvePublishedAt(List<ConfigPackageResponse> appliedPackages,
                           String tenantId,
                           boolean sectionsFallbackUsed) {
        Instant fromPackages = appliedPackages.stream()
            .map(ConfigPackageResponse::updatedAt)
            .map(Instant::parse)
            .max(Instant::compareTo)
            .orElse(Instant.EPOCH);

        Instant fromSections = sectionsFallbackUsed
            ? Instant.EPOCH
            : checkinSectionRepository.findByTenantIdAndActiveTrueOrderBySortOrderAscUpdatedAtAsc(tenantId)
            .stream()
            .map(CheckinSectionEntity::getUpdatedAt)
            .max(Instant::compareTo)
            .orElse(Instant.EPOCH);

        return fromPackages.isAfter(fromSections) ? fromPackages : fromSections;
        }

        private boolean sectionMatchesAssetType(CheckinSectionEntity section, String assetType) {
        return sectionMatchesAssetType(section.getAssetType(), assetType);
        }

        private boolean sectionMatchesAssetType(String sectionAssetType, String assetType) {
        if (sectionAssetType == null || sectionAssetType.isBlank()) {
            return true;
        }
        if (assetType == null || assetType.isBlank()) {
            return false;
        }
        return sectionAssetType.equalsIgnoreCase(assetType);
        }

        private List<String> parseDesiredItems(String desiredItemsJson) {
        try {
            return objectMapper.readValue(desiredItemsJson, new TypeReference<>() {});
        } catch (Exception exception) {
            return List.of();
        }
        }

        private List<CheckinConfigResponse.CheckinSectionDto> defaultSections() {
        return List.of(
            new CheckinConfigResponse.CheckinSectionDto(
                "fachada",
                "Fachada",
                true,
                new CheckinConfigResponse.PhotoPolicyDto(1, 5),
                List.of("orientacao", "material")
            ),
            new CheckinConfigResponse.CheckinSectionDto(
                "ambiente",
                "Ambiente",
                true,
                new CheckinConfigResponse.PhotoPolicyDto(1, 8),
                List.of("estado", "iluminacao")
            ),
            new CheckinConfigResponse.CheckinSectionDto(
                "elemento",
                "Elemento",
                false,
                new CheckinConfigResponse.PhotoPolicyDto(0, 5),
                List.of("detalhe", "patologia")
            )
        );
        }
}
