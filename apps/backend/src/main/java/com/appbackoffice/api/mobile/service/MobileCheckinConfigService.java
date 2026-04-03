package com.appbackoffice.api.mobile.service;

import com.appbackoffice.api.config.ConfigPackageService;
import com.appbackoffice.api.config.dto.ConfigPackageResponse;
import com.appbackoffice.api.config.dto.ConfigResolveResponse;
import com.appbackoffice.api.config.dto.ConfigRulesDto;
import com.appbackoffice.api.mobile.dto.CheckinConfigResponse;
import com.appbackoffice.api.mobile.entity.CheckinSectionEntity;
import com.appbackoffice.api.mobile.repository.CheckinSectionRepository;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
public class MobileCheckinConfigService {

    private final ConfigPackageService configPackageService;
    private final CheckinSectionRepository checkinSectionRepository;
    private final ObjectMapper objectMapper;

    public MobileCheckinConfigService(ConfigPackageService configPackageService,
                                      CheckinSectionRepository checkinSectionRepository,
                                      ObjectMapper objectMapper) {
        this.configPackageService = configPackageService;
        this.checkinSectionRepository = checkinSectionRepository;
        this.objectMapper = objectMapper;
    }

    public CheckinConfigResponse resolve(String tenantId, String actorId, String tipoImovel) {
        ConfigResolveResponse resolveResponse = configPackageService.resolveForMobile(tenantId, actorId, null);
        ConfigRulesDto effective = resolveResponse.result().effective();

        Map<String, Object> step1 = new LinkedHashMap<>();
        step1.put("tipos", List.of("Urbano", "Rural", "Comercial", "Industrial"));
        step1.put("subtiposPorTipo", Map.of("Urbano", List.of("Apartamento", "Casa", "Sobrado", "Terreno")));
        if (tipoImovel != null && !tipoImovel.isBlank()) {
            step1.put("requestedTipoImovel", tipoImovel);
        }

        Map<String, Object> step2 = new LinkedHashMap<>();
        step2.put("camposFotos", List.of("fachada", "logradouro"));
        step2.put("gruposOpcoes", List.of("infraestrutura_servicos"));
        step2.put("photoPolicy", Map.of(
                "min", effective.cameraMinPhotos() != null ? effective.cameraMinPhotos() : 1,
                "max", effective.cameraMaxPhotos() != null ? effective.cameraMaxPhotos() : 5
        ));
        step2.put("featureFlags", Map.of(
                "enableVoiceCommands", effective.enableVoiceCommands() != null ? effective.enableVoiceCommands() : true,
                "requireBiometric", effective.requireBiometric() != null ? effective.requireBiometric() : false
        ));
        if (effective.theme() != null || effective.appUpdateChannel() != null) {
            Map<String, Object> presentation = new LinkedHashMap<>();
            presentation.put("theme", effective.theme());
            presentation.put("appUpdateChannel", effective.appUpdateChannel());
            step2.put("presentation", presentation);
        }

        List<CheckinConfigResponse.CheckinSectionDto> sections = resolveSections(tenantId, tipoImovel);
        Instant publishedAt = resolvePublishedAt(resolveResponse.result().appliedPackages(), tenantId, sections.isEmpty());
        Instant publishedAtForResponse = publishedAt.equals(Instant.EPOCH) ? Instant.now() : publishedAt;

        return new CheckinConfigResponse(
                buildVersion(resolveResponse.result().appliedPackages(), publishedAt),
            publishedAtForResponse.toString(),
                step1,
                step2,
                sections,
                buildNotes(resolveResponse.result().appliedPackages())
        );
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
                    "Compatibilidade v1: campos existentes não serão removidos/renomeados sem nova major.",
                    "Configuração efetiva padrão aplicada: nenhum pacote ativo encontrado para o tenant/usuário.",
                    "Tenant e correlationId são obrigatórios para rastreabilidade ponta a ponta."
            );
        }

        String appliedIds = appliedPackages.stream()
                .map(ConfigPackageResponse::id)
                .toList()
                .toString();

        return List.of(
                "Compatibilidade v1: campos existentes não serão removidos/renomeados sem nova major.",
                "Configuração efetiva derivada de pacotes ativos: " + appliedIds,
                "Tenant e correlationId são obrigatórios para rastreabilidade ponta a ponta."
        );
    }

        private List<CheckinConfigResponse.CheckinSectionDto> resolveSections(String tenantId, String tipoImovel) {
        List<CheckinSectionEntity> all = checkinSectionRepository
            .findByTenantIdAndActiveTrueOrderBySortOrderAscUpdatedAtAsc(tenantId);

        List<CheckinSectionEntity> matched = all.stream()
            .filter(section -> sectionMatchesTipoImovel(section, tipoImovel))
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

        private boolean sectionMatchesTipoImovel(CheckinSectionEntity section, String tipoImovel) {
        if (section.getTipoImovel() == null || section.getTipoImovel().isBlank()) {
            return true;
        }
        if (tipoImovel == null || tipoImovel.isBlank()) {
            return false;
        }
        return section.getTipoImovel().equalsIgnoreCase(tipoImovel);
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
