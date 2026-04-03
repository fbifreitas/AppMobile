package com.appbackoffice.api.integration.service;

import com.appbackoffice.api.integration.entity.IntegrationDemandEntity;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

@Component
public class LogIntegrationEventPublisher implements IntegrationEventPublisher {

    private static final Logger LOGGER = LoggerFactory.getLogger(LogIntegrationEventPublisher.class);

    @Override
    public void publishDemandCreated(IntegrationDemandEntity demand) {
        LOGGER.info("DemandCreated event simulated: externalId={}, tenantId={}, demandId={}",
                demand.getExternalId(), demand.getTenantId(), demand.getId());
    }
}
