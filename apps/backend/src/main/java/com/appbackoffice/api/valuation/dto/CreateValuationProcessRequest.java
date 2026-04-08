package com.appbackoffice.api.valuation.dto;

public record CreateValuationProcessRequest(
        Long inspectionId,
        String method,
        Long assignedAnalystId
) {
}
