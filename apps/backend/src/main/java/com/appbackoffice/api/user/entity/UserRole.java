package com.appbackoffice.api.user.entity;

public enum UserRole {
    ADMIN,         // acesso total ao backoffice
    OPERATOR,      // gerencia jobs e vistorias
    FIELD_AGENT,   // vistoriador em campo (app mobile)
    VIEWER         // somente leitura
}
