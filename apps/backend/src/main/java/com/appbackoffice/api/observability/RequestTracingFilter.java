package com.appbackoffice.api.observability;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.MDC;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.UUID;

@Component
@Order(Ordered.HIGHEST_PRECEDENCE)
public class RequestTracingFilter extends OncePerRequestFilter {

    public static final String CORRELATION_ID_HEADER = "X-Correlation-Id";
    public static final String TRACE_ID_HEADER = "X-Trace-Id";
    public static final String CORRELATION_ID_MDC_KEY = "correlationId";
    public static final String TRACE_ID_MDC_KEY = "traceId";
    public static final String CORRELATION_ID_REQUEST_ATTRIBUTE = RequestTracingFilter.class.getName() + ".correlationId";
    public static final String TRACE_ID_REQUEST_ATTRIBUTE = RequestTracingFilter.class.getName() + ".traceId";

    private final OperationalEventRecorder operationalEventRecorder;

    public RequestTracingFilter(OperationalEventRecorder operationalEventRecorder) {
        this.operationalEventRecorder = operationalEventRecorder;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        String correlationId = resolveCorrelationId(request);
        String traceId = generateTraceId();
        long startedAt = System.currentTimeMillis();

        response.setHeader(CORRELATION_ID_HEADER, correlationId);
        response.setHeader(TRACE_ID_HEADER, traceId);
        request.setAttribute(CORRELATION_ID_REQUEST_ATTRIBUTE, correlationId);
        request.setAttribute(TRACE_ID_REQUEST_ATTRIBUTE, traceId);

        MDC.put(CORRELATION_ID_MDC_KEY, correlationId);
        MDC.put(TRACE_ID_MDC_KEY, traceId);
        try {
            filterChain.doFilter(request, response);
        } finally {
            operationalEventRecorder.recordHttpInteraction(request, response, System.currentTimeMillis() - startedAt);
            MDC.remove(CORRELATION_ID_MDC_KEY);
            MDC.remove(TRACE_ID_MDC_KEY);
        }
    }

    private String resolveCorrelationId(HttpServletRequest request) {
        String headerValue = request.getHeader(CORRELATION_ID_HEADER);
        if (StringUtils.hasText(headerValue)) {
            return headerValue.trim();
        }
        return "srv-" + UUID.randomUUID();
    }

    private String generateTraceId() {
        return UUID.randomUUID().toString().replace("-", "");
    }
}
