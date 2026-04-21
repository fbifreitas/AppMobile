package com.appbackoffice.api.intelligence.service;

import com.appbackoffice.api.job.entity.InspectionCase;
import org.springframework.stereotype.Component;

@Component
public class OperationalReferenceRegionResolver {

    public Region resolve(InspectionCase inspectionCase) {
        if (inspectionCase == null) {
            return new Region(null, null, null);
        }
        return resolve(inspectionCase.getPropertyAddress());
    }

    public Region resolve(String address) {
        if (address == null || address.isBlank()) {
            return new Region(null, null, null);
        }
        String[] parts = address.split(",");
        String district = parts.length >= 3 ? safePart(parts[2]) : null;
        String cityState = parts.length >= 4 ? safePart(parts[3]) : (parts.length >= 2 ? safePart(parts[parts.length - 1]) : null);
        if (cityState == null) {
            return new Region(null, null, district);
        }
        String normalized = cityState.trim();
        String state = null;
        String city = normalized;
        if (normalized.matches(".*\\b[A-Z]{2}$")) {
            int idx = normalized.lastIndexOf(' ');
            if (idx > 0) {
                city = normalized.substring(0, idx).trim();
                state = normalized.substring(idx + 1).trim();
            }
        }
        return new Region(state, city, district);
    }

    private String safePart(String value) {
        String normalized = value == null ? null : value.trim();
        return normalized == null || normalized.isBlank() ? null : normalized;
    }

    public record Region(String state, String city, String district) {
    }
}
