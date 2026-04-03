package com.appbackoffice.api.mobile.service;

import com.appbackoffice.api.config.ConfigPackageService;
import com.appbackoffice.api.config.dto.ConfigPackageResponse;
import com.appbackoffice.api.config.dto.ConfigResolveResponse;
import com.appbackoffice.api.config.dto.ConfigRulesDto;
import com.appbackoffice.api.mobile.dto.CheckinConfigResponse;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
public class MobileCheckinConfigService {

    private final ConfigPackageService configPackageService;

    public MobileCheckinConfigService(ConfigPackageService configPackageService) {
        this.configPackageService = configPackageService;
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

        return new CheckinConfigResponse(
                buildVersion(resolveResponse.result().appliedPackages()),
                step1,
                step2,
                buildNotes(resolveResponse.result().appliedPackages())
        );
    }

    private String buildVersion(List<ConfigPackageResponse> appliedPackages) {
        if (appliedPackages.isEmpty()) {
            return "v1-default";
        }

        Instant latest = appliedPackages.stream()
                .map(ConfigPackageResponse::updatedAt)
                .map(Instant::parse)
                .max(Instant::compareTo)
                .orElse(Instant.EPOCH);

        return "cfg-" + latest.toEpochMilli();
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
}
