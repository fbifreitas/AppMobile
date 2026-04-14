package com.appbackoffice.api.config;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
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
class ConfigPackageLifecycleIntegrationTest {

        private static final String CORRELATION_ID = "corr-config-123";

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void publishApproveResolveAndRollback_followExpectedLifecycle() throws Exception {
        String publishPayload = """
                {
                  "actorId": "operator-web",
                  "actorRole": "operator",
                  "scope": "user",
                  "tenantId": "tenant-alpha",
                  "selector": {
                    "userId": "user-42"
                  },
                  "rollout": {
                    "activation": "immediate"
                  },
                  "rules": {
                    "appUpdateChannel": "hotfix",
                    "enableVoiceCommands": false
                  }
                }
                """;

        MvcResult publishResult = mockMvc.perform(post("/api/backoffice/config/packages")
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Role", "COORDINATOR")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(publishPayload))
                .andReturn();

        assertThat(publishResult.getResponse().getStatus()).isEqualTo(201);
        JsonNode publishBody = objectMapper.readTree(publishResult.getResponse().getContentAsString());
        String packageId = publishBody.at("/result/created/id").asText();
        assertThat(publishBody.at("/result/created/status").asText()).isEqualTo("pending_approval");

        MvcResult resolveBeforeApproval = mockMvc.perform(get("/api/backoffice/config/resolve")
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .queryParam("tenantId", "tenant-alpha")
                        .queryParam("userId", "user-42")
                        .queryParam("actorRole", "tenant_admin"))
                .andReturn();

        assertThat(resolveBeforeApproval.getResponse().getStatus()).isEqualTo(200);
        JsonNode beforeApprovalBody = objectMapper.readTree(resolveBeforeApproval.getResponse().getContentAsString());
        assertThat(beforeApprovalBody.at("/result/effective/appUpdateChannel").isMissingNode()).isTrue();

        MvcResult approveResult = mockMvc.perform(post("/api/backoffice/config/packages/approve")
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Role", "TENANT_ADMIN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "packageId": "%s",
                                                                                                                                        "tenantId": "tenant-alpha",
                                  "actorId": "approver-web",
                                  "actorRole": "tenant_admin"
                                }
                                """.formatted(packageId)))
                .andReturn();

        assertThat(approveResult.getResponse().getStatus()).isEqualTo(200);

        MvcResult resolveAfterApproval = mockMvc.perform(get("/api/backoffice/config/resolve")
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .queryParam("tenantId", "tenant-alpha")
                        .queryParam("userId", "user-42")
                        .queryParam("actorRole", "tenant_admin"))
                .andReturn();

        JsonNode afterApprovalBody = objectMapper.readTree(resolveAfterApproval.getResponse().getContentAsString());
        assertThat(afterApprovalBody.at("/result/effective/appUpdateChannel").asText()).isEqualTo("hotfix");
        assertThat(afterApprovalBody.at("/result/effective/enableVoiceCommands").asBoolean()).isFalse();

        MvcResult rollbackResult = mockMvc.perform(post("/api/backoffice/config/packages/rollback")
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Role", "TENANT_ADMIN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "packageId": "%s",
                                                                                                                                        "tenantId": "tenant-alpha",
                                  "actorId": "approver-web",
                                  "actorRole": "tenant_admin"
                                }
                                """.formatted(packageId)))
                .andReturn();

        assertThat(rollbackResult.getResponse().getStatus()).isEqualTo(200);

        MvcResult resolveAfterRollback = mockMvc.perform(get("/api/backoffice/config/resolve")
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .queryParam("tenantId", "tenant-alpha")
                        .queryParam("userId", "user-42")
                        .queryParam("actorRole", "tenant_admin"))
                .andReturn();

        JsonNode afterRollbackBody = objectMapper.readTree(resolveAfterRollback.getResponse().getContentAsString());
        assertThat(afterRollbackBody.at("/result/effective/appUpdateChannel").isMissingNode()).isTrue();
    }

    @Test
    void approveEndpoint_rejectsInsufficientRole() throws Exception {
        MvcResult publishResult = mockMvc.perform(post("/api/backoffice/config/packages")
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Role", "COORDINATOR")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "actorId": "operator-web",
                                  "actorRole": "operator",
                                  "scope": "user",
                                  "tenantId": "tenant-alpha",
                                  "selector": {
                                    "userId": "user-42"
                                  },
                                  "rules": {
                                    "appUpdateChannel": "pilot"
                                  }
                                }
                                """))
                .andReturn();

        String packageId = objectMapper.readTree(publishResult.getResponse().getContentAsString())
                .at("/result/created/id")
                .asText();

        MvcResult approveResult = mockMvc.perform(post("/api/backoffice/config/packages/approve")
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Role", "OPERATOR")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "packageId": "%s",
                                                                                                                                        "tenantId": "tenant-alpha",
                                  "actorId": "operator-web",
                                  "actorRole": "operator"
                                }
                                """.formatted(packageId)))
                .andReturn();

        assertThat(approveResult.getResponse().getStatus()).isEqualTo(403);
        assertThat(approveResult.getResponse().getContentAsString())
                .contains("AUTH_FORBIDDEN");
    }

    @Test
    void approveEndpoint_rejectsCrossTenantPackageMutation() throws Exception {
        MvcResult publishResult = mockMvc.perform(post("/api/backoffice/config/packages")
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Role", "COORDINATOR")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "actorId": "operator-web",
                                  "actorRole": "operator",
                                  "scope": "tenant",
                                  "tenantId": "tenant-alpha",
                                  "rules": {
                                    "appUpdateChannel": "pilot"
                                  }
                                }
                                """))
                .andReturn();

        String packageId = objectMapper.readTree(publishResult.getResponse().getContentAsString())
                .at("/result/created/id")
                .asText();

        MvcResult approveResult = mockMvc.perform(post("/api/backoffice/config/packages/approve")
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Role", "TENANT_ADMIN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "packageId": "%s",
                                  "tenantId": "tenant-beta",
                                  "actorId": "approver-web",
                                  "actorRole": "tenant_admin"
                                }
                                """.formatted(packageId)))
                .andReturn();

        assertThat(approveResult.getResponse().getStatus()).isEqualTo(404);
        assertThat(approveResult.getResponse().getContentAsString())
                .contains("Pacote nao encontrado");
    }

    @Test
    void resolveShouldMergeExpandedDynamicRulesWithUserPrecedence() throws Exception {
        MvcResult tenantPublishResult = mockMvc.perform(post("/api/backoffice/config/packages")
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Role", "COORDINATOR")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "actorId": "operator-web",
                                  "actorRole": "operator",
                                  "scope": "tenant",
                                  "tenantId": "tenant-dynamic-resolve",
                                  "rules": {
                                    "step1": {
                                      "tipos": ["Urbano"],
                                      "subtiposPorTipo": {
                                        "Urbano": ["Casa"]
                                      },
                                      "contextos": ["Rua"],
                                      "levels": [
                                        {
                                          "id": "contexto",
                                          "label": "Por onde deseja começar?",
                                          "required": true,
                                          "options": ["Rua"]
                                        }
                                      ]
                                    },
                                    "step2": {
                                      "byTipo": {
                                        "RESIDENTIAL": {
                                          "visivel": true,
                                          "camposFotos": [
                                            {
                                              "id": "fachada",
                                              "titulo": "Fachada",
                                              "icon": "home_work_outlined",
                                              "obrigatorio": true,
                                              "cameraMacroLocal": "Rua",
                                              "cameraAmbiente": "Fachada"
                                            }
                                          ]
                                        }
                                      }
                                    },
                                    "camera": {
                                      "propertyTypes": {
                                        "RESIDENTIAL": {
                                          "levels": [
                                            {
                                              "id": "ambiente",
                                              "label": "Ambiente",
                                              "required": true,
                                              "options": ["Fachada"]
                                            }
                                          ]
                                        }
                                      }
                                    }
                                  }
                                }
                                """))
                .andReturn();

        String tenantPackageId = objectMapper.readTree(tenantPublishResult.getResponse().getContentAsString())
                .at("/result/created/id")
                .asText();

        mockMvc.perform(post("/api/backoffice/config/packages/approve")
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Role", "TENANT_ADMIN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "packageId": "%s",
                                  "tenantId": "tenant-dynamic-resolve",
                                  "actorId": "approver-web",
                                  "actorRole": "tenant_admin"
                                }
                                """.formatted(tenantPackageId)))
                .andReturn();

        MvcResult userPublishResult = mockMvc.perform(post("/api/backoffice/config/packages")
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Role", "COORDINATOR")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "actorId": "operator-web",
                                  "actorRole": "operator",
                                  "scope": "user",
                                  "tenantId": "tenant-dynamic-resolve",
                                  "selector": {
                                    "userId": "user-42"
                                  },
                                  "rules": {
                                    "step1": {
                                      "contextos": ["Área interna"],
                                      "levelsBySubtipo": {
                                        "Urbano": {
                                          "Casa": [
                                            {
                                              "id": "contexto",
                                              "label": "Fluxo interno",
                                              "required": true,
                                              "options": ["Área interna"]
                                            }
                                          ]
                                        }
                                      }
                                    },
                                    "step2": {
                                      "byTipo": {
                                        "RESIDENTIAL": {
                                          "obrigatoria": true,
                                          "gruposOpcoes": [
                                            {
                                              "id": "infraestrutura",
                                              "titulo": "Infraestrutura",
                                              "opcoes": [
                                                {
                                                  "id": "calcada",
                                                  "label": "Calçada"
                                                }
                                              ]
                                            }
                                          ]
                                        }
                                      }
                                    },
                                    "camera": {
                                      "propertyTypes": {
                                        "RESIDENTIAL": {
                                          "levelsBySubtipo": {
                                            "casa": [
                                              {
                                                "id": "elemento",
                                                "label": "Elemento",
                                                "required": true,
                                                "options": ["Porta"]
                                              }
                                            ]
                                          }
                                        }
                                      }
                                    }
                                  }
                                }
                                """))
                .andReturn();

        String userPackageId = objectMapper.readTree(userPublishResult.getResponse().getContentAsString())
                .at("/result/created/id")
                .asText();

        mockMvc.perform(post("/api/backoffice/config/packages/approve")
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Role", "TENANT_ADMIN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "packageId": "%s",
                                  "tenantId": "tenant-dynamic-resolve",
                                  "actorId": "approver-web",
                                  "actorRole": "tenant_admin"
                                }
                                """.formatted(userPackageId)))
                .andReturn();

        MvcResult resolveResult = mockMvc.perform(get("/api/backoffice/config/resolve")
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .queryParam("tenantId", "tenant-dynamic-resolve")
                        .queryParam("userId", "user-42")
                        .queryParam("actorRole", "tenant_admin"))
                .andReturn();

        assertThat(resolveResult.getResponse().getStatus()).isEqualTo(200);
        JsonNode body = objectMapper.readTree(resolveResult.getResponse().getContentAsString());

        assertThat(body.at("/result/appliedPackages").isArray()).isTrue();
        assertThat(body.at("/result/appliedPackages").size()).isEqualTo(2);
        assertThat(body.at("/result/effective/step1/tipos/0").asText()).isEqualTo("Urbano");
        assertThat(body.at("/result/effective/step1/contextos/0").asText()).isEqualTo("Área interna");
        assertThat(body.at("/result/effective/step1/levelsBySubtipo/Urbano/Casa/0/id").asText()).isEqualTo("contexto");
        assertThat(body.at("/result/effective/step2/byTipo/RESIDENTIAL/visivel").asBoolean()).isTrue();
        assertThat(body.at("/result/effective/step2/byTipo/RESIDENTIAL/obrigatoria").asBoolean()).isTrue();
        assertThat(body.at("/result/effective/step2/byTipo/RESIDENTIAL/camposFotos/0/id").asText()).isEqualTo("fachada");
        assertThat(body.at("/result/effective/step2/byTipo/RESIDENTIAL/gruposOpcoes/0/id").asText()).isEqualTo("infraestrutura");
        assertThat(body.at("/result/effective/camera/propertyTypes/RESIDENTIAL/levels/0/id").asText()).isEqualTo("ambiente");
        assertThat(body.at("/result/effective/camera/propertyTypes/RESIDENTIAL/levelsBySubtipo/casa/0/id").asText()).isEqualTo("elemento");
    }
}
