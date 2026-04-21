package com.appbackoffice.api.intelligence.service;

import com.appbackoffice.api.intelligence.model.ExecutionPlanPayload;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.Collection;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

@Component
public class OperationalReferenceCompositionSupport {

    public List<ExecutionPlanPayload.CameraEnvironmentProfile> mergeProfiles(
            Collection<ExecutionPlanPayload.CameraEnvironmentProfile> left,
            Collection<ExecutionPlanPayload.CameraEnvironmentProfile> right
    ) {
        Map<String, ExecutionPlanPayload.CameraEnvironmentProfile> merged = new LinkedHashMap<>();
        if (left != null) {
            for (ExecutionPlanPayload.CameraEnvironmentProfile item : left) {
                if (item == null || item.photoLocation() == null || item.photoLocation().isBlank()) {
                    continue;
                }
                merged.put(item.photoLocation(), item);
            }
        }
        if (right != null) {
            for (ExecutionPlanPayload.CameraEnvironmentProfile item : right) {
                if (item == null || item.photoLocation() == null || item.photoLocation().isBlank()) {
                    continue;
                }
                merged.merge(item.photoLocation(), item, this::mergeProfile);
            }
        }
        return List.copyOf(merged.values());
    }

    public List<ExecutionPlanPayload.CameraEnvironmentProfile> filterByPhotoLocations(
            Collection<ExecutionPlanPayload.CameraEnvironmentProfile> source,
            Collection<String> photoLocations
    ) {
        Set<String> allowed = new LinkedHashSet<>();
        if (photoLocations != null) {
            for (String item : photoLocations) {
                if (item != null && !item.isBlank()) {
                    allowed.add(item.trim());
                }
            }
        }
        if (allowed.isEmpty()) {
            return source == null ? List.of() : List.copyOf(source);
        }
        List<ExecutionPlanPayload.CameraEnvironmentProfile> filtered = new ArrayList<>();
        if (source != null) {
            for (ExecutionPlanPayload.CameraEnvironmentProfile item : source) {
                if (item != null && allowed.contains(item.photoLocation())) {
                    filtered.add(item);
                }
            }
        }
        return List.copyOf(filtered);
    }

    public ExecutionPlanPayload.CameraEnvironmentProfile mergeProfile(
            ExecutionPlanPayload.CameraEnvironmentProfile left,
            ExecutionPlanPayload.CameraEnvironmentProfile right
    ) {
        Map<String, ExecutionPlanPayload.CameraElementProfile> mergedElements = new LinkedHashMap<>();
        left.elements().forEach(item -> mergedElements.put(item.element(), item));
        right.elements().forEach(item -> mergedElements.merge(item.element(), item, this::mergeElement));
        return new ExecutionPlanPayload.CameraEnvironmentProfile(
                left.macroLocal() == null || left.macroLocal().isBlank() ? right.macroLocal() : left.macroLocal(),
                left.photoLocation(),
                left.required() || right.required(),
                Math.max(left.minPhotos(), right.minPhotos()),
                List.copyOf(mergedElements.values()),
                mergeSource(left.source(), right.source()),
                mergeBindings(left.normativeBindings(), right.normativeBindings())
        );
    }

    public ExecutionPlanPayload.CameraElementProfile mergeElement(
            ExecutionPlanPayload.CameraElementProfile left,
            ExecutionPlanPayload.CameraElementProfile right
    ) {
        Set<String> materials = new LinkedHashSet<>(left.materials());
        materials.addAll(right.materials());
        Set<String> states = new LinkedHashSet<>(left.states());
        states.addAll(right.states());
        return new ExecutionPlanPayload.CameraElementProfile(
                left.element(),
                List.copyOf(materials),
                List.copyOf(states)
        );
    }

    private String mergeSource(String left, String right) {
        if ("HYBRID".equals(left) || "HYBRID".equals(right)) {
            return "HYBRID";
        }
        if (left == null || left.isBlank()) {
            return right == null || right.isBlank() ? "COMPOSITION" : right;
        }
        if (right == null || right.isBlank() || left.equals(right)) {
            return left;
        }
        return "HYBRID";
    }

    private List<ExecutionPlanPayload.NormativeBinding> mergeBindings(
            List<ExecutionPlanPayload.NormativeBinding> left,
            List<ExecutionPlanPayload.NormativeBinding> right
    ) {
        Map<String, ExecutionPlanPayload.NormativeBinding> merged = new LinkedHashMap<>();
        if (left != null) {
            for (ExecutionPlanPayload.NormativeBinding item : left) {
                merged.put(item.dimension(), item);
            }
        }
        if (right != null) {
            for (ExecutionPlanPayload.NormativeBinding item : right) {
                merged.put(item.dimension(), item);
            }
        }
        return List.copyOf(merged.values());
    }
}
