package com.appbackoffice.api.auth.config;

import org.springframework.beans.factory.InitializingBean;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

@Component
public class JwtSecretValidator implements InitializingBean {

    @Value("${auth.jwt.secret:}")
    private String jwtSecret;

    @Value("${auth.jwt.require-secret:true}")
    private boolean requireSecret;

    @Override
    public void afterPropertiesSet() {
        if (StringUtils.hasText(jwtSecret)) {
            return;
        }

        if (requireSecret) {
            throw new IllegalStateException(
                    "auth.jwt.secret must be configured when auth.jwt.require-secret=true"
            );
        }
    }
}
