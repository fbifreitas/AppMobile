package com.appbackoffice.api.user.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

@Schema(name = "CreateUserRequest", description = "Criação de usuário pelo backoffice web ou importação AD")
public record CreateUserRequest(
        @NotBlank @Email @Schema(example = "joao@empresa.com") String email,
        @NotBlank @Schema(example = "João Silva") String nome,
        @NotBlank @Schema(example = "PJ", description = "CLT ou PJ") String tipo,
        @Schema(example = "12345678901") String cpf,
        @Schema(example = "12345678901234") String cnpj,
        @NotNull @Schema(example = "FIELD_AGENT", description = "ADMIN, OPERATOR, FIELD_AGENT ou VIEWER") String role,
        @Schema(example = "ad-uuid-001", description = "ID externo (AD Object GUID ou equivalente)") String externalId
) {}
