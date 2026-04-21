package com.appaigateway.config;

import org.springframework.beans.factory.InitializingBean;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

@Component
public class GatewaySecretsValidator implements InitializingBean {

    @Value("${app.gateway.api-key:}")
    private String gatewayApiKey;

    @Value("${app.gateway.require-secret:true}")
    private boolean requireGatewaySecret;

    @Value("${app.ai.gemini.enabled:true}")
    private boolean geminiEnabled;

    @Value("${app.ai.gemini.api-key:}")
    private String geminiApiKey;

    @Override
    public void afterPropertiesSet() {
        if (requireGatewaySecret && !StringUtils.hasText(gatewayApiKey)) {
            throw new IllegalStateException("app.gateway.api-key must be configured when app.gateway.require-secret=true");
        }

        if (geminiEnabled && !StringUtils.hasText(geminiApiKey)) {
            throw new IllegalStateException("app.ai.gemini.api-key must be configured when app.ai.gemini.enabled=true");
        }
    }
}
