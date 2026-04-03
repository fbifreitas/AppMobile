package com.appbackoffice.api.auth.service;

import com.appbackoffice.api.contract.ApiContractException;
import com.appbackoffice.api.contract.ErrorSeverity;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jws;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.Instant;
import java.util.Date;
import java.util.List;
import java.util.UUID;

@Service
public class JwtTokenService {

    private final SecretKey signingKey;
    private final Duration accessTtl;
    private final Duration refreshTtl;

    public JwtTokenService(@Value("${auth.jwt.secret}") String jwtSecret,
                           @Value("${auth.jwt.access-token-minutes:15}") long accessTokenMinutes,
                           @Value("${auth.jwt.refresh-token-days:7}") long refreshTokenDays) {
        this.signingKey = Keys.hmacShaKeyFor(jwtSecret.getBytes(StandardCharsets.UTF_8));
        this.accessTtl = Duration.ofMinutes(accessTokenMinutes);
        this.refreshTtl = Duration.ofDays(refreshTokenDays);
    }

    public String generateAccessToken(Long userId,
                                      String tenantId,
                                      String organizationUnitId,
                                      List<String> roles) {
        Instant now = Instant.now();
        Instant expiresAt = now.plus(accessTtl);

        return Jwts.builder()
                .subject(String.valueOf(userId))
                .id(UUID.randomUUID().toString())
                .claim("tid", tenantId)
                .claim("oid", organizationUnitId)
                .claim("roles", roles)
                .issuedAt(Date.from(now))
                .expiration(Date.from(expiresAt))
                .signWith(signingKey)
                .compact();
    }

    public JwtPrincipal parseAndValidate(String token) {
        try {
            Jws<Claims> jws = Jwts.parser()
                    .verifyWith(signingKey)
                    .build()
                    .parseSignedClaims(token);
            Claims body = jws.getPayload();

            Long userId = Long.valueOf(body.getSubject());
            String tenantId = body.get("tid", String.class);
            String organizationUnitId = body.get("oid", String.class);
            @SuppressWarnings("unchecked")
            List<String> roles = body.get("roles", List.class);

            return new JwtPrincipal(
                    userId,
                    tenantId,
                    organizationUnitId,
                    roles == null ? List.of() : roles,
                    body.getExpiration().toInstant(),
                    body.getId()
            );
        } catch (JwtException | IllegalArgumentException ex) {
            throw new ApiContractException(
                    HttpStatus.UNAUTHORIZED,
                    "AUTH_INVALID_TOKEN",
                    "Token inválido ou expirado",
                    ErrorSeverity.ERROR,
                    "Faça login novamente para obter uma sessão válida.",
                    null
            );
        }
    }

    public Duration accessTokenTtl() {
        return accessTtl;
    }

    public Duration refreshTokenTtl() {
        return refreshTtl;
    }
}
