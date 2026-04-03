package com.appbackoffice.api.integration.dto;

import com.fasterxml.jackson.databind.JsonNode;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.time.Instant;

public record DemandCreateRequest(
        @NotBlank String externalId,
        @NotBlank String tenantId,
        @NotBlank String requestedBy,
        @NotBlank String inspectionType,
        @NotNull Instant requestedDeadline,
        @NotNull @Valid DemandAddressRequest propertyAddress,
        JsonNode clientData
) {
}
