#!/usr/bin/env python3
import json
import sys
from typing import Any, Dict, List, Optional, Set, Tuple


HTTP_METHODS = {
    "get",
    "put",
    "post",
    "delete",
    "options",
    "head",
    "patch",
    "trace",
}


def load_spec(path: str) -> Dict:
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def collect_ops(spec: Dict) -> Set[Tuple[str, str]]:
    paths = spec.get("paths", {})
    ops = set()
    for p, methods in paths.items():
        if not isinstance(methods, dict):
            continue
        for m in methods.keys():
            method = m.lower()
            if method in HTTP_METHODS:
                ops.add((p, method))
    return ops


def response_codes(spec: Dict, path: str, method: str) -> Set[str]:
    op = spec.get("paths", {}).get(path, {}).get(method, {})
    responses = op.get("responses", {})
    return set(responses.keys())


def operation_parameters(spec: Dict, path: str, method: str) -> List[Dict[str, Any]]:
    path_item = spec.get("paths", {}).get(path, {})
    operation = path_item.get(method, {}) if isinstance(path_item, dict) else {}

    params: List[Dict[str, Any]] = []
    if isinstance(path_item, dict):
        path_params = path_item.get("parameters", [])
        if isinstance(path_params, list):
            params.extend([p for p in path_params if isinstance(p, dict)])

    if isinstance(operation, dict):
        op_params = operation.get("parameters", [])
        if isinstance(op_params, list):
            params.extend([p for p in op_params if isinstance(p, dict)])

    return params


def required_header_names(spec: Dict, path: str, method: str) -> Set[str]:
    required_headers: Set[str] = set()
    for param in operation_parameters(spec, path, method):
        if str(param.get("in", "")).lower() != "header":
            continue
        if not bool(param.get("required", False)):
            continue
        name = param.get("name")
        if isinstance(name, str) and name.strip():
            required_headers.add(name.strip().lower())
    return required_headers


def schema_props(spec: Dict) -> Dict[str, Set[str]]:
    out: Dict[str, Set[str]] = {}
    schemas = spec.get("components", {}).get("schemas", {})
    for name, schema in schemas.items():
        props = schema.get("properties", {}) if isinstance(schema, dict) else {}
        if isinstance(props, dict):
            out[name] = set(props.keys())
    return out


def schema_required(spec: Dict) -> Dict[str, Set[str]]:
    out: Dict[str, Set[str]] = {}
    schemas = spec.get("components", {}).get("schemas", {})
    for name, schema in schemas.items():
        required = schema.get("required", []) if isinstance(schema, dict) else []
        if isinstance(required, list):
            out[name] = set(required)
    return out


def resolve_schema_refs(schema_node: Any) -> Set[str]:
    refs: Set[str] = set()

    if isinstance(schema_node, dict):
        ref = schema_node.get("$ref")
        if isinstance(ref, str):
            refs.add(ref)

        for key in ("allOf", "anyOf", "oneOf"):
            items = schema_node.get(key)
            if isinstance(items, list):
                for item in items:
                    refs.update(resolve_schema_refs(item))

        items = schema_node.get("items")
        if items is not None:
            refs.update(resolve_schema_refs(items))

        props = schema_node.get("properties")
        if isinstance(props, dict):
            for value in props.values():
                refs.update(resolve_schema_refs(value))

        addl = schema_node.get("additionalProperties")
        if addl is not None:
            refs.update(resolve_schema_refs(addl))

    elif isinstance(schema_node, list):
        for item in schema_node:
            refs.update(resolve_schema_refs(item))

    return refs


def response_schema_refs(spec: Dict, path: str, method: str, code: str) -> Set[str]:
    op = spec.get("paths", {}).get(path, {}).get(method, {})
    responses = op.get("responses", {}) if isinstance(op, dict) else {}
    response = responses.get(code, {}) if isinstance(responses, dict) else {}
    content = response.get("content", {}) if isinstance(response, dict) else {}

    refs: Set[str] = set()
    if isinstance(content, dict):
        for media in content.values():
            if not isinstance(media, dict):
                continue
            refs.update(resolve_schema_refs(media.get("schema")))

    return refs


def schema_enum_values(spec: Dict, schema_name: str) -> Optional[Set[str]]:
    schema = spec.get("components", {}).get("schemas", {}).get(schema_name)
    if not isinstance(schema, dict):
        return None
    enum = schema.get("enum")
    if not isinstance(enum, list):
        return None
    return {str(v) for v in enum}


def check_breaking(base: Dict, curr: Dict) -> List[str]:
    failures: List[str] = []

    base_ops = collect_ops(base)
    curr_ops = collect_ops(curr)

    missing_ops = sorted(base_ops - curr_ops)
    for path, method in missing_ops:
        failures.append(f"Removed operation: {method.upper()} {path}")

    for path, method in sorted(base_ops & curr_ops):
        base_codes = response_codes(base, path, method)
        curr_codes = response_codes(curr, path, method)
        removed_codes = sorted(base_codes - curr_codes)
        for code in removed_codes:
            failures.append(
                f"Removed response code: {method.upper()} {path} -> {code}"
            )

        # Semantic gate for canonical error envelope:
        # if base operation had CanonicalErrorResponse in 4xx responses,
        # current operation must preserve this reference for the same status code.
        for code in sorted(base_codes & curr_codes):
            if not code.startswith("4"):
                continue

            base_refs = response_schema_refs(base, path, method, code)
            curr_refs = response_schema_refs(curr, path, method, code)
            canonical_ref = "#/components/schemas/CanonicalErrorResponse"

            if canonical_ref in base_refs and canonical_ref not in curr_refs:
                failures.append(
                    "Missing canonical error schema in 4xx response: "
                    f"{method.upper()} {path} -> {code}"
                )

        # Semantic gate for required header contract (context/idempotency).
        # Base-oriented rule: only preserve what `main` already requires.
        base_required_headers = required_header_names(base, path, method)
        curr_required_headers = required_header_names(curr, path, method)
        removed_required_headers = sorted(base_required_headers - curr_required_headers)
        for header in removed_required_headers:
            failures.append(
                "Removed required header parameter: "
                f"{method.upper()} {path} -> {header}"
            )

    base_props = schema_props(base)
    curr_props = schema_props(curr)
    for schema_name, props in sorted(base_props.items()):
        if schema_name not in curr_props:
            failures.append(f"Removed schema: components.schemas.{schema_name}")
            continue
        removed_props = sorted(props - curr_props[schema_name])
        for prop in removed_props:
            failures.append(
                f"Removed schema property: components.schemas.{schema_name}.{prop}"
            )

    base_required = schema_required(base)
    curr_required = schema_required(curr)
    for schema_name, req in sorted(base_required.items()):
        if schema_name not in curr_required:
            continue
        removed_required = sorted(req - curr_required[schema_name])
        for prop in removed_required:
            failures.append(
                f"Removed required constraint: components.schemas.{schema_name}.{prop}"
            )

    # Semantic gate for canonical error schema required fields.
    canonical_schema = "CanonicalErrorResponse"
    if canonical_schema in base_required:
        base_req = base_required.get(canonical_schema, set())
        curr_req = curr_required.get(canonical_schema, set())
        removed_required = sorted(base_req - curr_req)
        for prop in removed_required:
            failures.append(
                f"Removed canonical required field: components.schemas.{canonical_schema}.{prop}"
            )

    # Semantic gate for severity enum values used by canonical error.
    base_severity = schema_enum_values(base, "ErrorSeverity")
    curr_severity = schema_enum_values(curr, "ErrorSeverity")
    if base_severity is not None and curr_severity is not None:
        removed_levels = sorted(base_severity - curr_severity)
        for level in removed_levels:
            failures.append(
                f"Removed error severity level: components.schemas.ErrorSeverity.{level}"
            )

    return failures


def main() -> int:
    if len(sys.argv) != 3:
        print("Usage: openapi_breaking_check.py <base.json> <current.json>")
        return 2

    base = load_spec(sys.argv[1])
    curr = load_spec(sys.argv[2])
    failures = check_breaking(base, curr)

    if failures:
        print("Breaking changes detected:")
        for f in failures:
            print(f"- {f}")
        return 1

    print("No breaking changes detected between base and current OpenAPI specs.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
