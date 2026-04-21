package com.appbackoffice.api.intelligence.service;

import com.appbackoffice.api.intelligence.port.ResearchProvider;
import com.appbackoffice.api.intelligence.port.ResearchProviderRequest;
import com.appbackoffice.api.intelligence.port.ResearchProviderResponse;
import com.fasterxml.jackson.databind.node.JsonNodeFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
@ConditionalOnMissingBean(ResearchProvider.class)
public class DisabledResearchProvider implements ResearchProvider {

    @Override
    public ResearchProviderResponse execute(ResearchProviderRequest request) {
        return new ResearchProviderResponse(
                "AI_GATEWAY_DISABLED",
                null,
                "v1",
                List.of(),
                List.of(),
                JsonNodeFactory.instance.objectNode()
                        .put("status", "disabled")
                        .put("tenantId", request.tenantId())
                        .put("caseId", request.caseId()),
                JsonNodeFactory.instance.objectNode()
                        .put("status", "manual_review_required")
                        .put("reason", "AI gateway is not configured"),
                0.0,
                true,
                List.of("AI_GATEWAY_DISABLED")
        );
    }
}
