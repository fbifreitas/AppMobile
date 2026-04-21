package com.appbackoffice.api.intelligence.dto;

import java.util.List;

public record CaptureGatePolicyResponse(
        String tenantId,
        String policyVersion,
        List<GateItem> gates
) {
    public record GateItem(
            String code,
            String title,
            String description,
            boolean blockingCapture,
            String source
    ) {
    }
}
