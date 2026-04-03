package com.appbackoffice.api.user.entity;

public enum UserSource {
    MOBILE_ONBOARDING,   // usuário se cadastrou pelo app mobile
    WEB_CREATED,         // admin criou pelo backoffice
    AD_IMPORT            // importado de diretório (AD/LDAP)
}
