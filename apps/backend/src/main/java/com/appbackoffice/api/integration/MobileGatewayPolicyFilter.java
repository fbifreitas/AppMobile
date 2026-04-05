package com.appbackoffice.api.integration;

import com.appbackoffice.api.contract.ApiContractException;
import com.appbackoffice.api.contract.ErrorSeverity;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.time.Instant;
import java.util.ArrayDeque;
import java.util.Deque;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Component
public class MobileGatewayPolicyFilter extends OncePerRequestFilter {

    private static final String API_VERSION = "v1";
    private static final int RATE_LIMIT_PER_MINUTE = 120;
    private static final long WINDOW_SECONDS = 60;
    private final Map<String, Deque<Long>> requestsByKey = new ConcurrentHashMap<>();

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        String uri = request.getRequestURI();
        return uri == null || !uri.startsWith("/api/mobile/");
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        enforceRateLimit(request);
        response.setHeader("X-Api-Version", API_VERSION);
        filterChain.doFilter(request, response);
    }

    private void enforceRateLimit(HttpServletRequest request) {
        String tenantId = normalize(request.getHeader("X-Tenant-Id"), "unknown-tenant");
        String actorId = normalize(request.getHeader("X-Actor-Id"), "unknown-actor");
        String key = tenantId + "::" + actorId;

        long now = Instant.now().getEpochSecond();
        Deque<Long> deque = requestsByKey.computeIfAbsent(key, ignored -> new ArrayDeque<>());
        synchronized (deque) {
            while (!deque.isEmpty() && (now - deque.peekFirst()) >= WINDOW_SECONDS) {
                deque.removeFirst();
            }

            if (deque.size() >= RATE_LIMIT_PER_MINUTE) {
                throw new ApiContractException(
                        HttpStatus.TOO_MANY_REQUESTS,
                        "REQ_RATE_LIMITED",
                        "Limite de requisicoes mobile excedido",
                        ErrorSeverity.ERROR,
                        "Aguarde alguns segundos antes de tentar novamente.",
                        "limitPerMinute=" + RATE_LIMIT_PER_MINUTE
                );
            }

            deque.addLast(now);
        }
    }

    private String normalize(String value, String fallback) {
        if (!StringUtils.hasText(value)) {
            return fallback;
        }
        return value.trim();
    }
}
