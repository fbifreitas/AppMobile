package com.appbackoffice.api.user.dto;

import io.swagger.v3.oas.annotations.media.Schema;

import java.util.List;

@Schema(name = "UserListResponse", description = "Lista de usuários com paginação")
public record UserListResponse(
        @Schema(description = "Total de usuários encontrados") int total,
        @Schema(description = "Lista de usuários") List<UserResponse> users
) {
}
