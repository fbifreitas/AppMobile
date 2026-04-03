package com.appbackoffice.api.integration.dto;

import jakarta.validation.constraints.NotBlank;

public record DemandAddressRequest(
        @NotBlank String street,
        @NotBlank String city,
        @NotBlank String state,
        @NotBlank String zipCode
) {
}
