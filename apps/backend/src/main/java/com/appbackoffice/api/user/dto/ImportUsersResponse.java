package com.appbackoffice.api.user.dto;

import io.swagger.v3.oas.annotations.media.Schema;

import java.util.List;

@Schema(name = "ImportUsersResponse", description = "Resultado de importação em batch")
public record ImportUsersResponse(
        @Schema(description = "Total enviado") int submitted,
        @Schema(description = "Importados com sucesso") int imported,
        @Schema(description = "Ignorados (duplicados)") int skipped,
        @Schema(description = "Usuários importados") List<UserResponse> users,
        @Schema(description = "Emails ignorados por já existirem") List<String> skippedEmails
) {}
