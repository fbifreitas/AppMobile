package com.appbackoffice.api.user.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.LocalDate;

@Schema(name = "CreateUserRequest", description = "Criação de usuário pelo backoffice web ou importação AD")
public record CreateUserRequest(
        @NotBlank @Email @Schema(example = "joao@empresa.com") String email,
        @NotBlank @Schema(example = "João Silva") String nome,
        @NotBlank @Schema(example = "PJ", description = "CLT ou PJ") String tipo,
        @Schema(example = "12345678901") String cpf,
        @Schema(example = "12345678901234") String cnpj,
        @Schema(example = "1990-05-20", description = "Data de nascimento necessaria para primeiro acesso") LocalDate birthDate,
        @Schema(example = "5511999999999", description = "Telefone para hint de entrega do primeiro acesso") String phone,
        @NotNull @Schema(example = "FIELD_AGENT", description = "ADMIN, OPERATOR, FIELD_AGENT ou VIEWER") String role,
        @Schema(example = "ad-uuid-001", description = "ID externo (AD Object GUID ou equivalente)") String externalId
) {}
