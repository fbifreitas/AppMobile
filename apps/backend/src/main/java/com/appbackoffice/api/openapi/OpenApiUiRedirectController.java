package com.appbackoffice.api.openapi;

import io.swagger.v3.oas.annotations.Hidden;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

@Hidden
@Controller
public class OpenApiUiRedirectController {

    @GetMapping("/api/swagger")
    public String redirectToSwaggerUi() {
        return "redirect:/webjars/swagger-ui/index.html?url=/api/openapi/v1";
    }
}