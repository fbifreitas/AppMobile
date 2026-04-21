package com.appbackoffice.api.intelligence.service;

import com.appbackoffice.api.intelligence.dto.NormativeMatrixResponse;
import org.springframework.stereotype.Service;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

@Service
public class NormativeMatrixService {

    public NormativeMatrixResponse resolve(String tenantId) {
        return new NormativeMatrixResponse(
                tenantId,
                "normative-matrix-v1",
                List.of(
                        buildApartmentProfile(),
                        buildHouseProfile(),
                        buildCommercialProfile(),
                        buildRuralProfile()
                )
        );
    }

    public NormativeMatrixResponse.Profile resolveProfile(String assetType,
                                                          String assetSubtype,
                                                          String refinedAssetSubtype) {
        String normalizedType = normalize(assetType);
        String normalizedSubtype = normalize(refinedAssetSubtype != null && !refinedAssetSubtype.isBlank()
                ? refinedAssetSubtype
                : assetSubtype);
        if ("urbano".equals(normalizedType) && normalizedSubtype.contains("apartamento")) {
            return buildApartmentProfile();
        }
        if ("urbano".equals(normalizedType) && (normalizedSubtype.contains("casa") || normalizedSubtype.contains("sobrado"))) {
            return buildHouseProfile();
        }
        if ("comercial".equals(normalizedType)) {
            return buildCommercialProfile();
        }
        if ("rural".equals(normalizedType)) {
            return buildRuralProfile();
        }
        return buildGenericProfile(assetType, assetSubtype, refinedAssetSubtype);
    }

    private NormativeMatrixResponse.Profile buildApartmentProfile() {
        return new NormativeMatrixResponse.Profile(
                "Urbano",
                "Apartamento",
                null,
                List.of(
                        rule("IDENTIFICACAO_EXTERNA", "Identificacao externa", true, 2, 4,
                                List.of("Fachada + Numero do portao", "Fachada + Acesso ao imovel")),
                        rule("ACESSO_IMOVEL", "Acesso ao imovel", true, 1, 3,
                                List.of("Portaria", "Hall de entrada")),
                        rule("AMBIENTE_SOCIAL", "Ambiente social", true, 1, 4,
                                List.of("Sala de estar", "Sala de jantar")),
                        rule("AMBIENTE_MOLHADO", "Ambiente molhado", true, 1, 4,
                                List.of("Cozinha", "Banheiro", "Lavanderia")),
                        rule("CONSERVACAO_ACABAMENTO", "Conservacao e acabamento", true, 1, 8,
                                List.of("Piso", "Parede", "Teto", "Esquadria"))
                )
        );
    }

    private NormativeMatrixResponse.Profile buildHouseProfile() {
        return new NormativeMatrixResponse.Profile(
                "Urbano",
                "Casa",
                null,
                List.of(
                        rule("IDENTIFICACAO_EXTERNA", "Identificacao externa", true, 2, 4,
                                List.of("Fachada + Numero", "Fachada + Portao")),
                        rule("ACESSO_IMOVEL", "Acesso ao imovel", true, 1, 3,
                                List.of("Portao", "Garagem", "Entrada principal")),
                        rule("AMBIENTE_SOCIAL", "Ambiente social", true, 1, 4,
                                List.of("Sala", "Varanda")),
                        rule("AMBIENTE_MOLHADO", "Ambiente molhado", true, 1, 4,
                                List.of("Cozinha", "Banheiro", "Lavanderia")),
                        rule("AREA_EXTERNA", "Area externa", false, 0, 4,
                                List.of("Quintal", "Corredor lateral", "Edicula"))
                )
        );
    }

    private NormativeMatrixResponse.Profile buildCommercialProfile() {
        return new NormativeMatrixResponse.Profile(
                "Comercial",
                "Loja",
                null,
                List.of(
                        rule("IDENTIFICACAO_EXTERNA", "Identificacao externa", true, 2, 4,
                                List.of("Fachada + Numero", "Fachada + Logradouro")),
                        rule("ACESSO_IMOVEL", "Acesso ao imovel", true, 1, 3,
                                List.of("Entrada principal", "Porta de acesso")),
                        rule("AREA_OPERACIONAL", "Area operacional", true, 1, 6,
                                List.of("Salao principal", "Atendimento", "Retaguarda")),
                        rule("CONSERVACAO_ACABAMENTO", "Conservacao e acabamento", true, 1, 8,
                                List.of("Piso", "Parede", "Forro", "Esquadria"))
                )
        );
    }

    private NormativeMatrixResponse.Profile buildRuralProfile() {
        return new NormativeMatrixResponse.Profile(
                "Rural",
                "Sitio",
                null,
                List.of(
                        rule("IDENTIFICACAO_EXTERNA", "Identificacao externa", true, 2, 5,
                                List.of("Acesso principal", "Porteira", "Estrada interna")),
                        rule("BENFEITORIAS", "Benfeitorias principais", true, 1, 8,
                                List.of("Casa sede", "Galpao", "Curral")),
                        rule("ENTORNO_USO", "Entorno e uso", true, 1, 6,
                                List.of("Pastagem", "Lavoura", "Area de apoio"))
                )
        );
    }

    private NormativeMatrixResponse.Profile buildGenericProfile(String assetType,
                                                                String assetSubtype,
                                                                String refinedAssetSubtype) {
        return new NormativeMatrixResponse.Profile(
                assetType,
                assetSubtype,
                refinedAssetSubtype,
                List.of(
                        rule("IDENTIFICACAO_EXTERNA", "Identificacao externa", true, 2, 4,
                                List.of("Fachada", "Acesso")),
                        rule("COMPOSICAO_MINIMA", "Composicao minima", true, 1, 6,
                                List.of("Ambiente principal", "Area de apoio"))
                )
        );
    }

    private NormativeMatrixResponse.RuleItem rule(String dimension,
                                                  String title,
                                                  boolean required,
                                                  int minPhotos,
                                                  Integer maxPhotos,
                                                  List<String> alternatives) {
        return new NormativeMatrixResponse.RuleItem(
                dimension,
                title,
                required,
                minPhotos,
                maxPhotos,
                "FINALIZATION",
                true,
                alternatives
        );
    }

    private String normalize(String value) {
        return value == null ? "" : value.trim().toLowerCase(Locale.ROOT);
    }
}
