package com.appbackoffice.api.integration.service;

import com.appbackoffice.api.integration.entity.IntegrationDemandEntity;

public interface IntegrationEventPublisher {
    void publishDemandCreated(IntegrationDemandEntity demand);
}
