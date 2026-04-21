package com.appbackoffice.api.mobile.dto;

public record JobClientAbsentRequest(
        String reason,
        String responderName,
        ClientAbsentEvidenceRequest evidence
) {
    public record ClientAbsentEvidenceRequest(
            String fileName,
            String contentType,
            String imageBase64,
            String capturedAt,
            Double latitude,
            Double longitude,
            Double accuracy
    ) {
    }
}
