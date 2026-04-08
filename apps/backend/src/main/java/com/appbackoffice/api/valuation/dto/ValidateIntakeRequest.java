package com.appbackoffice.api.valuation.dto;

import com.fasterxml.jackson.databind.JsonNode;

public record ValidateIntakeRequest(
        String result,
        JsonNode issues,
        String notes
) {
}
