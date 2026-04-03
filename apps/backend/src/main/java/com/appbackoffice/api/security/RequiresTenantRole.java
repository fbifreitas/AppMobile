package com.appbackoffice.api.security;

import com.appbackoffice.api.identity.entity.MembershipRole;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

@Target({ElementType.METHOD, ElementType.TYPE})
@Retention(RetentionPolicy.RUNTIME)
public @interface RequiresTenantRole {
    MembershipRole[] value();
}
