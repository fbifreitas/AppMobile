package com.appbackoffice.api.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

@Component
public class ConfigSigningSecretValidator implements InitializingBean {

    private static final Logger LOGGER = LoggerFactory.getLogger(ConfigSigningSecretValidator.class);

    @Value("${integration.config-signing.hmac-key:}")
    private String hmacKey;

    @Value("${integration.config-signing.require-secret:false}")
    private boolean requireSecret;

    @Override
    public void afterPropertiesSet() {
        if (StringUtils.hasText(hmacKey)) {
            return;
        }

        if (requireSecret) {
            throw new IllegalStateException(
                    "integration.config-signing.hmac-key must be configured when integration.config-signing.require-secret=true"
            );
        }

        LOGGER.warn("Config signing secret is not configured; mobile config payloads will be returned without signature headers.");
    }
}
