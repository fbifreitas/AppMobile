package com.appbackoffice.api.mobile;

import com.appbackoffice.api.config.ConfigAuditEntryRepository;
import com.appbackoffice.api.config.ConfigPackageRepository;
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

    @BeforeEach
    void setUp() {
        configAuditEntryRepository.deleteAll();
        configPackageRepository.deleteAll();
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

        MvcResult result = mockMvc.perform(get("/api/mobile/checkin-config")
                        .header("X-Tenant-Id", "tenant-mobile-config")
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Id", "42")
                        .queryParam("tipoImovel", "RESIDENTIAL"))
                .andReturn();

        assertThat(result.getResponse().getStatus()).isEqualTo(200);
        JsonNode body = objectMapper.readTree(result.getResponse().getContentAsString());

        assertThat(body.get("version").asText()).startsWith("cfg-");
        assertThat(body.at("/step1/requestedTipoImovel").asText()).isEqualTo("RESIDENTIAL");
        assertThat(body.at("/step2/photoPolicy/min").asInt()).isEqualTo(2);
        assertThat(body.at("/step2/photoPolicy/max").asInt()).isEqualTo(7);
        assertThat(body.at("/step2/featureFlags/enableVoiceCommands").asBoolean()).isFalse();
        assertThat(body.at("/step2/featureFlags/requireBiometric").asBoolean()).isTrue();
        assertThat(body.at("/step2/presentation/theme").asText()).isEqualTo("operational");
        assertThat(body.get("compatibilityNotes").toString()).contains(packageId);
    }

    @Test
    void shouldFallbackToDefaultWhenNoActivePackageExists() throws Exception {
        MvcResult result = mockMvc.perform(get("/api/mobile/checkin-config")
                        .header("X-Tenant-Id", "tenant-without-config")
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Id", "999"))
                .andReturn();

        assertThat(result.getResponse().getStatus()).isEqualTo(200);
        JsonNode body = objectMapper.readTree(result.getResponse().getContentAsString());
        assertThat(body.get("version").asText()).isEqualTo("v1-default");
        assertThat(body.at("/step2/photoPolicy/min").asInt()).isEqualTo(1);
        assertThat(body.at("/step2/photoPolicy/max").asInt()).isEqualTo(5);
        assertThat(body.get("compatibilityNotes").toString()).contains("nenhum pacote ativo encontrado");
    }
}
