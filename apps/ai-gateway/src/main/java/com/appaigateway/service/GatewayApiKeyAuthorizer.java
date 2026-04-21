package com.appaigateway.service;

import com.appaigateway.controller.ResearchGatewayController.UnauthorizedGatewayRequestException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class GatewayApiKeyAuthorizer {

    private final String expectedApiKey;

    public GatewayApiKeyAuthorizer(@Value("${app.gateway.api-key:}") String expectedApiKey) {
        this.expectedApiKey = expectedApiKey;
    }

    public void authorize(String providedApiKey) {
        if (!expectedApiKey.equals(providedApiKey)) {
            throw new UnauthorizedGatewayRequestException();
        }
    }
}
