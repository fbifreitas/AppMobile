package com.appbackoffice.api.intelligence.service;

import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;

@Component
public class OperationalReferenceCatalogBootstrapRunner implements ApplicationRunner {

    private final OperationalReferenceCatalogBootstrapService bootstrapService;

    public OperationalReferenceCatalogBootstrapRunner(OperationalReferenceCatalogBootstrapService bootstrapService) {
        this.bootstrapService = bootstrapService;
    }

    @Override
    public void run(ApplicationArguments args) {
        bootstrapService.bootstrapIfEmpty();
    }
}
