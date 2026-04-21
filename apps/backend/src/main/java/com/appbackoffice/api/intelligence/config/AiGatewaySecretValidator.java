package com.appbackoffice.api.intelligence.config;

import org.springframework.beans.factory.InitializingBean;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

@Component
public class AiGatewaySecretValidator implements InitializingBean {

    @Value("${integration.ai-gateway.enabled:false}")
    private boolean enabled;

    @Value("${integration.ai-gateway.api-key:}")
    private String apiKey;

    @Value("${integration.ai-gateway.require-secret:true}")
    private boolean requireSecret;

    @Override
    public void afterPropertiesSet() {
        if (!enabled || !requireSecret) {
            return;
        }

        if (!StringUtils.hasText(apiKey)) {
            throw new IllegalStateException(
                    "integration.ai-gateway.api-key must be configured when integration.ai-gateway.enabled=true and integration.ai-gateway.require-secret=true"
            );
        }
    }
}
