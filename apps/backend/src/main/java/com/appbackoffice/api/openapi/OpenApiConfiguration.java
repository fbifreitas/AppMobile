package com.appbackoffice.api.openapi;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.info.License;
import io.swagger.v3.oas.models.servers.Server;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenApiConfiguration {

    @Bean
    public OpenAPI backofficeOpenApi() {
        return new OpenAPI()
                .info(new Info()
                        .title("AppMobile Backoffice API")
                        .version("v1")
                        .description("OpenAPI v1 com política de compatibilidade retroativa: "
                                + "adições não quebrantes são permitidas em v1; breaking changes exigem nova versão major. "
                                + "Contrato de erro canônico com code/severity/guidance aplicado aos endpoints críticos.")
                        .license(new License().name("Proprietary")))
                .addServersItem(new Server().url("/").description("Default server"));
    }
}
