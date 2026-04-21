package com.appbackoffice.api.intelligence;

import com.appbackoffice.api.intelligence.model.ResolvedOperationalReferenceProfile;
import com.appbackoffice.api.intelligence.port.ResearchFact;
import com.appbackoffice.api.intelligence.port.ResearchProviderResponse;
import com.appbackoffice.api.intelligence.repository.OperationalReferenceProfileRepository;
import com.appbackoffice.api.intelligence.service.OperationalReferenceCatalogService;
import com.appbackoffice.api.job.entity.InspectionCase;
import com.fasterxml.jackson.databind.node.JsonNodeFactory;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.context.ActiveProfiles;

import java.time.Instant;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
@ActiveProfiles("test")
class OperationalReferenceCatalogIntegrationTest {

    @Autowired
    private OperationalReferenceProfileRepository repository;

    @Autowired
    private OperationalReferenceCatalogService operationalReferenceCatalogService;

    @MockBean
    private com.appbackoffice.api.intelligence.port.ResearchProvider researchProvider;

    @Test
    void shouldBootstrapPersistedOperationalReferenceProfiles() {
        assertThat(repository.count()).isGreaterThanOrEqualTo(15);
    }

    @Test
    void shouldResolvePersistedApartmentReferenceProfile() {
        InspectionCase inspectionCase = new InspectionCase(
                "tenant-compass",
                "CASE-REF-001",
                "Av. Alvaro Ramos, 760, Quarta Parada, Sao Paulo SP",
                null,
                null,
                "RESIDENTIAL",
                Instant.now().plusSeconds(3600)
        );

        ResearchProviderResponse response = new ResearchProviderResponse(
                "AI_GATEWAY",
                "gemini-2.5-flash",
                "v1",
                List.of(
                        new ResearchFact("location_city", "Sao Paulo", 0.91, "AI_GATEWAY", "Detected from address"),
                        new ResearchFact("property_subtype", "Apartamento", 0.93, "AI_GATEWAY", "Detected from research"),
                        new ResearchFact("private_area_m2", "300", 0.84, "AI_GATEWAY", "Detected from listing")
                ),
                List.of(),
                JsonNodeFactory.instance.objectNode(),
                JsonNodeFactory.instance.objectNode(),
                0.84,
                false,
                List.of()
        );

        ResolvedOperationalReferenceProfile profile = operationalReferenceCatalogService.resolve(
                inspectionCase,
                response,
                "Urbano",
                "Apartamento",
                "Apartamento",
                "Alto padrao"
        );

        assertThat(profile.source()).isEqualTo("GLOBAL_REFERENCE");
        assertThat(profile.candidateAssetSubtypes()).contains("Apartamento", "Apartamento alto padrao", "Duplex");
        assertThat(profile.photoLocations()).contains("Fachada", "Cozinha", "Sala de estar", "Hall privativo");
        assertThat(profile.compositionProfiles()).anyMatch(item -> item.photoLocation().equals("Cozinha"));
        assertThat(profile.compositionProfiles()).anyMatch(item -> item.photoLocation().equals("Hall privativo"));
    }
}
