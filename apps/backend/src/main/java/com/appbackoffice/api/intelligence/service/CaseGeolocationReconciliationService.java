package com.appbackoffice.api.intelligence.service;

import com.appbackoffice.api.intelligence.port.ResearchProviderResponse;
import com.appbackoffice.api.job.entity.InspectionCase;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
public class CaseGeolocationReconciliationService {

    private final ResearchFactResolver factResolver;

    public CaseGeolocationReconciliationService(ResearchFactResolver factResolver) {
        this.factResolver = factResolver;
    }

    public ResolvedCoordinates resolve(InspectionCase inspectionCase, ResearchProviderResponse providerResponse) {
        Double latitude = firstDouble(
                providerResponse,
                "property_latitude",
                "location_latitude",
                "latitude",
                "lat"
        ).orElse(inspectionCase.getPropertyLatitude());
        Double longitude = firstDouble(
                providerResponse,
                "property_longitude",
                "location_longitude",
                "longitude",
                "lng",
                "lon"
        ).orElse(inspectionCase.getPropertyLongitude());
        return new ResolvedCoordinates(latitude, longitude);
    }

    private Optional<Double> firstDouble(ResearchProviderResponse response, String... keys) {
        return factResolver.firstValue(response, keys)
                .map(this::parseDouble)
                .filter(value -> value != null);
    }

    private Double parseDouble(String raw) {
        try {
            return Double.parseDouble(raw.replace(",", ".").replaceAll("[^0-9.\\-]", ""));
        } catch (NumberFormatException exception) {
            return null;
        }
    }

    public record ResolvedCoordinates(
            Double latitude,
            Double longitude
    ) {
    }
}
