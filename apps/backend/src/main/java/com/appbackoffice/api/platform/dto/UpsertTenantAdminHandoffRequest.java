package com.appbackoffice.api.platform.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

public record UpsertTenantAdminHandoffRequest(
        @NotBlank @Email String email,
        @NotBlank String nome,
        @NotBlank String tipo,
        String cpf,
        String cnpj,
        String externalId,
        @NotBlank String temporaryPassword
) {
}
