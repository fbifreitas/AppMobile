package com.appbackoffice.api.security;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class SecurityWebMvcConfig implements WebMvcConfigurer {

    private final TenantRoleAuthorizationInterceptor tenantRoleAuthorizationInterceptor;

    public SecurityWebMvcConfig(TenantRoleAuthorizationInterceptor tenantRoleAuthorizationInterceptor) {
        this.tenantRoleAuthorizationInterceptor = tenantRoleAuthorizationInterceptor;
    }

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(tenantRoleAuthorizationInterceptor).addPathPatterns("/**");
    }
}
