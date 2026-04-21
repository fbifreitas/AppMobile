package com.appaigateway.controller;

import com.appaigateway.dto.CaseResearchRequest;
import com.appaigateway.dto.CaseResearchResponse;
import com.appaigateway.service.GatewayApiKeyAuthorizer;
import com.appaigateway.service.ResearchGatewayService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/v1/research/cases")
public class ResearchGatewayController {

    private final GatewayApiKeyAuthorizer gatewayApiKeyAuthorizer;
    private final ResearchGatewayService researchGatewayService;

    public ResearchGatewayController(GatewayApiKeyAuthorizer gatewayApiKeyAuthorizer,
                                     ResearchGatewayService researchGatewayService) {
        this.gatewayApiKeyAuthorizer = gatewayApiKeyAuthorizer;
        this.researchGatewayService = researchGatewayService;
    }

    @PostMapping
    public CaseResearchResponse execute(@RequestHeader("X-Api-Key") String apiKey,
                                        @Valid @RequestBody CaseResearchRequest request) {
        gatewayApiKeyAuthorizer.authorize(apiKey);
        return researchGatewayService.execute(request);
    }

    @ResponseStatus(HttpStatus.UNAUTHORIZED)
    public static class UnauthorizedGatewayRequestException extends RuntimeException {
        public UnauthorizedGatewayRequestException() {
            super("Invalid gateway API key");
        }
    }
}
