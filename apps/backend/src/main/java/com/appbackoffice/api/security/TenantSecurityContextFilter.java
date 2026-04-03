package com.appbackoffice.api.security;

import com.appbackoffice.api.auth.service.JwtPrincipal;
import com.appbackoffice.api.auth.service.JwtTokenService;
import com.appbackoffice.api.contract.ApiContractException;
import com.appbackoffice.api.contract.ErrorSeverity;
import com.appbackoffice.api.identity.entity.Membership;
import com.appbackoffice.api.identity.entity.MembershipRole;
import com.appbackoffice.api.identity.entity.MembershipStatus;
import com.appbackoffice.api.identity.repository.MembershipRepository;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.EnumSet;
import java.util.List;
import java.util.Set;

@Component
public class TenantSecurityContextFilter extends OncePerRequestFilter {

    private final ObjectProvider<JwtTokenService> jwtTokenServiceProvider;
    private final ObjectProvider<MembershipRepository> membershipRepositoryProvider;

    public TenantSecurityContextFilter(ObjectProvider<JwtTokenService> jwtTokenServiceProvider,
                                       ObjectProvider<MembershipRepository> membershipRepositoryProvider) {
        this.jwtTokenServiceProvider = jwtTokenServiceProvider;
        this.membershipRepositoryProvider = membershipRepositoryProvider;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        try {
            resolveFromBearerIfPresent(request);
            filterChain.doFilter(request, response);
        } finally {
            TenantSecurityContextHolder.clear();
        }
    }

    private void resolveFromBearerIfPresent(HttpServletRequest request) {
        String authorizationHeader = request.getHeader("Authorization");
        if (!StringUtils.hasText(authorizationHeader) || !authorizationHeader.startsWith("Bearer ")) {
            return;
        }

        JwtTokenService jwtTokenService = jwtTokenServiceProvider.getIfAvailable();
        if (jwtTokenService == null) {
            return;
        }

        String token = authorizationHeader.substring("Bearer ".length());
        JwtPrincipal principal = jwtTokenService.parseAndValidate(token);

        MembershipRepository membershipRepository = membershipRepositoryProvider.getIfAvailable();
        Membership membership = null;
        if (membershipRepository != null) {
            membership = membershipRepository.findByUser_IdAndTenant_Id(principal.userId(), principal.tenantId())
                    .orElseThrow(() -> new ApiContractException(
                            HttpStatus.UNAUTHORIZED,
                            "AUTH_MEMBERSHIP_NOT_FOUND",
                            "Usuário sem membership ativa no tenant",
                            ErrorSeverity.ERROR,
                            "Contate o administrador para revisar permissões.",
                            "tenantId=" + principal.tenantId() + ", userId=" + principal.userId()
                    ));

            if (membership.getStatus() != MembershipStatus.ACTIVE) {
                throw new ApiContractException(
                        HttpStatus.UNAUTHORIZED,
                        "AUTH_MEMBERSHIP_INACTIVE",
                        "Membership inativa para autenticação",
                        ErrorSeverity.ERROR,
                        "Contate o administrador para reativar o acesso.",
                        "tenantId=" + principal.tenantId() + ", userId=" + principal.userId()
                );
            }
        }

        Set<MembershipRole> roles = resolveRoles(principal.roles(), membership);
        TenantSecurityContextHolder.setContext(new TenantSecurityContext(principal.userId(), principal.tenantId(), roles));
    }

    private Set<MembershipRole> resolveRoles(List<String> roleClaims, Membership membership) {
        EnumSet<MembershipRole> roles = EnumSet.noneOf(MembershipRole.class);

        if (roleClaims != null) {
            for (String roleClaim : roleClaims) {
                if (!StringUtils.hasText(roleClaim)) {
                    continue;
                }
                try {
                    roles.add(MembershipRole.valueOf(roleClaim));
                } catch (IllegalArgumentException ignored) {
                    // Ignore unknown claims to preserve backward compatibility.
                }
            }
        }

        if (roles.isEmpty() && membership != null) {
            roles.add(membership.getRole());
        }

        return roles;
    }
}
