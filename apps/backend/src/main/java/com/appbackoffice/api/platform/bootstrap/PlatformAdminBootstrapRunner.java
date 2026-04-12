package com.appbackoffice.api.platform.bootstrap;

import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;

@Component
public class PlatformAdminBootstrapRunner implements ApplicationRunner {

    private final PlatformAdminBootstrapService platformAdminBootstrapService;

    public PlatformAdminBootstrapRunner(PlatformAdminBootstrapService platformAdminBootstrapService) {
        this.platformAdminBootstrapService = platformAdminBootstrapService;
    }

    @Override
    public void run(ApplicationArguments args) {
        platformAdminBootstrapService.bootstrap();
    }
}
