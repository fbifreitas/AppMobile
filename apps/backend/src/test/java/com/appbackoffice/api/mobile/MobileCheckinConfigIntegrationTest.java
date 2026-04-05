package com.appbackoffice.api.mobile;

import com.appbackoffice.api.config.ConfigAuditEntryRepository;
import com.appbackoffice.api.config.ConfigPackageRepository;
import com.appbackoffice.api.mobile.entity.CheckinSectionEntity;
import com.appbackoffice.api.mobile.repository.CheckinSectionRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class MobileCheckinConfigIntegrationTest {

    private static final String CORRELATION_ID = "corr-mobile-config-001";

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private ConfigAuditEntryRepository configAuditEntryRepository;

    @Autowired
    private ConfigPackageRepository configPackageRepository;

    @Autowired
    private CheckinSectionRepository checkinSectionRepository;

    @BeforeEach
    void setUp() {
        configAuditEntryRepository.deleteAll();
        configPackageRepository.deleteAll();
        checkinSectionRepository.deleteAll();
    }

    @Test
    void shouldResolveRealCheckinConfigFromActiveUserPackage() throws Exception {
        MvcResult publishResult = mockMvc.perform(post("/api/backoffice/config/packages")
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Role", "COORDINATOR")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "actorId": "operator-web",
                                  "actorRole": "operator",
                                  "scope": "user",
                                  "tenantId": "tenant-mobile-config",
                                  "selector": {
                                    "userId": "42"
                                  },
                                  "rollout": {
                                    "activation": "immediate"
                                  },
                                  "rules": {
                                    "cameraMinPhotos": 2,
                                    "cameraMaxPhotos": 7,
                                    "enableVoiceCommands": false,
                                    "requireBiometric": true,
                                    "theme": "operational"
                                  }
                                }
                                """))
                .andReturn();

        String packageId = objectMapper.readTree(publishResult.getResponse().getContentAsString())
                .at("/result/created/id")
                .asText();

        mockMvc.perform(post("/api/backoffice/config/packages/approve")
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Role", "TENANT_ADMIN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "packageId": "%s",
                                  "tenantId": "tenant-mobile-config",
                                  "actorId": "approver-web",
                                  "actorRole": "tenant_admin"
                                }
                                """.formatted(packageId)))
                .andReturn();

        checkinSectionRepository.save(createSection(
                "tenant-mobile-config",
                "RESIDENTIAL",
                "fachada",
                "Fachada",
                true,
                2,
                7,
                List.of("orientacao", "material"),
                1
        ));

        MvcResult result = mockMvc.perform(get("/api/mobile/checkin-config")
                        .header("X-Tenant-Id", "tenant-mobile-config")
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Id", "42")
                        .header("X-Api-Version", "v1")
                        .queryParam("tipoImovel", "RESIDENTIAL"))
                .andReturn();

        assertThat(result.getResponse().getStatus()).isEqualTo(200);
        JsonNode body = objectMapper.readTree(result.getResponse().getContentAsString());

        assertThat(body.get("version").asText()).startsWith("cfg-");
        assertThat(body.get("publishedAt").asText()).isNotBlank();
        assertThat(body.at("/step1/requestedTipoImovel").asText()).isEqualTo("RESIDENTIAL");
        assertThat(body.at("/step2/photoPolicy/min").asInt()).isEqualTo(2);
        assertThat(body.at("/step2/photoPolicy/max").asInt()).isEqualTo(7);
        assertThat(body.at("/step2/featureFlags/enableVoiceCommands").asBoolean()).isFalse();
        assertThat(body.at("/step2/featureFlags/requireBiometric").asBoolean()).isTrue();
        assertThat(body.at("/step2/presentation/theme").asText()).isEqualTo("operational");
        assertThat(body.at("/sections/0/key").asText()).isEqualTo("fachada");
        assertThat(body.at("/sections/0/photos/min").asInt()).isEqualTo(2);
        assertThat(body.at("/sections/0/desiredItems/0").asText()).isEqualTo("orientacao");
        assertThat(body.get("compatibilityNotes").toString()).contains(packageId);
    }

    @Test
    void shouldFallbackToDefaultWhenNoActivePackageExists() throws Exception {
        MvcResult result = mockMvc.perform(get("/api/mobile/checkin-config")
                        .header("X-Tenant-Id", "tenant-without-config")
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Id", "999")
                        .header("X-Api-Version", "v1"))
                .andReturn();

        assertThat(result.getResponse().getStatus()).isEqualTo(200);
        JsonNode body = objectMapper.readTree(result.getResponse().getContentAsString());
        assertThat(body.get("version").asText()).isEqualTo("v1-default");
        assertThat(body.get("publishedAt").asText()).isNotBlank();
        assertThat(body.at("/step2/photoPolicy/min").asInt()).isEqualTo(1);
        assertThat(body.at("/step2/photoPolicy/max").asInt()).isEqualTo(5);
        assertThat(body.at("/sections/0/key").asText()).isEqualTo("fachada");
        assertThat(body.at("/sections/1/key").asText()).isEqualTo("ambiente");
        assertThat(body.get("compatibilityNotes").toString()).contains("nenhum pacote ativo encontrado");
    }

    private CheckinSectionEntity createSection(String tenantId,
                                               String tipoImovel,
                                               String key,
                                               String label,
                                               boolean mandatory,
                                               int photoMin,
                                               int photoMax,
                                               List<String> desiredItems,
                                               int sortOrder) throws Exception {
        CheckinSectionEntity entity = new CheckinSectionEntity();
        entity.setTenantId(tenantId);
        entity.setTipoImovel(tipoImovel);
        entity.setSectionKey(key);
        entity.setSectionLabel(label);
        entity.setMandatory(mandatory);
        entity.setPhotoMin(photoMin);
        entity.setPhotoMax(photoMax);
        entity.setDesiredItemsJson(objectMapper.writeValueAsString(desiredItems));
        entity.setSortOrder(sortOrder);
        entity.setActive(true);
        return entity;
    }
}
