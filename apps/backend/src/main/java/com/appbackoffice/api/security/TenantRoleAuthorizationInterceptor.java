package com.appbackoffice.api.security;

import com.appbackoffice.api.contract.ApiContractException;
import com.appbackoffice.api.contract.ErrorSeverity;
import com.appbackoffice.api.identity.entity.MembershipRole;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.method.HandlerMethod;
import org.springframework.web.servlet.HandlerInterceptor;

import java.util.Arrays;
import java.util.Locale;
import java.util.Set;

@Component
public class TenantRoleAuthorizationInterceptor implements HandlerInterceptor {

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
        if (!(handler instanceof HandlerMethod handlerMethod)) {
            return true;
        }

        RequiresTenantRole roleRequirement = findRequirement(handlerMethod);
        if (roleRequirement == null) {
            return true;
        }

        // Keep existing contract-error ordering: missing correlation must remain a 400 from validator.
        if (!StringUtils.hasText(request.getHeader("X-Correlation-Id"))) {
            return true;
        }

        TenantSecurityContext context = TenantSecurityContextHolder.getContext();
        MembershipRole effectiveRole = resolveEffectiveRole(request, context);

        if (effectiveRole == null) {
            throw new ApiContractException(
                    HttpStatus.UNAUTHORIZED,
                    "AUTH_INVALID_TOKEN",
                    "Token inválido ou ausente para autorização",
                    ErrorSeverity.ERROR,
                    "Envie Authorization: Bearer <token> ou informe o papel do ator no contexto legado.",
                    null
            );
        }

        ensureTenantMatch(request, context);

        boolean allowed = Arrays.stream(roleRequirement.value()).anyMatch(required -> required == effectiveRole);
        if (!allowed) {
            throw new ApiContractException(
                    HttpStatus.FORBIDDEN,
                    "AUTH_FORBIDDEN",
                    "Ação não permitida para o papel atual",
                    ErrorSeverity.ERROR,
                    "Solicite um papel com privilégio suficiente para executar esta operação.",
                    "required=" + Arrays.toString(roleRequirement.value()) + ", actual=" + effectiveRole
            );
        }
        return true;
    }

    private RequiresTenantRole findRequirement(HandlerMethod method) {
        RequiresTenantRole methodAnnotation = method.getMethodAnnotation(RequiresTenantRole.class);
        if (methodAnnotation != null) {
            return methodAnnotation;
        }
        return method.getBeanType().getAnnotation(RequiresTenantRole.class);
    }

    private MembershipRole resolveEffectiveRole(HttpServletRequest request, TenantSecurityContext context) {
        if (context != null && context.roles() != null && !context.roles().isEmpty()) {
            Set<MembershipRole> roles = context.roles();
            if (roles.contains(MembershipRole.PLATFORM_ADMIN)) {
                return MembershipRole.PLATFORM_ADMIN;
            }
            return roles.iterator().next();
        }

        String roleValue = request.getHeader("X-Actor-Role");
        if (!StringUtils.hasText(roleValue)) {
            roleValue = request.getParameter("actorRole");
        }

        if (StringUtils.hasText(roleValue)) {
            String normalized = roleValue.trim().toUpperCase(Locale.ROOT);
            if ("OPERATOR".equals(normalized)) {
                return MembershipRole.OPERATOR;
            }
            if ("TENANT_ADMIN".equals(normalized)) {
                return MembershipRole.TENANT_ADMIN;
            }
            if ("COORDINATOR".equals(normalized)) {
                return MembershipRole.COORDINATOR;
            }
            if ("AUDITOR".equals(normalized)) {
                return MembershipRole.AUDITOR;
            }
            if ("PLATFORM_ADMIN".equals(normalized)) {
                return MembershipRole.PLATFORM_ADMIN;
            }
            if ("FIELD_OPERATOR".equals(normalized)) {
                return MembershipRole.FIELD_OPERATOR;
            }
            if ("REGIONAL_COORD".equals(normalized)) {
                return MembershipRole.REGIONAL_COORD;
            }
        }

        // Legacy compatibility while web login is being integrated.
        if (StringUtils.hasText(request.getHeader("X-Actor-Id"))) {
            return MembershipRole.TENANT_ADMIN;
        }

        // Legacy compatibility for read paths that still rely on tenant context only.
        if (StringUtils.hasText(request.getHeader("X-Tenant-Id"))) {
            return MembershipRole.TENANT_ADMIN;
        }

        return null;
    }

    private void ensureTenantMatch(HttpServletRequest request, TenantSecurityContext context) {
        if (context == null || !StringUtils.hasText(context.tenantId())) {
            return;
        }

        String requestedTenant = request.getHeader("X-Tenant-Id");
        if (!StringUtils.hasText(requestedTenant)) {
            requestedTenant = request.getParameter("tenantId");
        }

        if (StringUtils.hasText(requestedTenant) && !context.tenantId().equals(requestedTenant)) {
            throw new ApiContractException(
                    HttpStatus.FORBIDDEN,
                    "TENANT_CONTEXT_MISMATCH",
                    "Token não pertence ao tenant informado na requisição",
                    ErrorSeverity.ERROR,
                    "Use um token do mesmo tenant do contexto solicitado.",
                    "tokenTenant=" + context.tenantId() + ", requestedTenant=" + requestedTenant
            );
        }
    }
}
