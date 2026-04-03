package com.appbackoffice.api.user.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;

import java.util.List;

@Schema(name = "ImportUsersRequest", description = "Importação em batch de usuários de AD/LDAP")
public record ImportUsersRequest(
        @Schema(example = "ad", description = "Fonte da importação: ad, ldap, csv") String source,
        @NotEmpty @Valid List<CreateUserRequest> users
) {}
