#!/usr/bin/env python3
import json
import sys
from typing import Dict, List, Set, Tuple


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
            ops.add((p, m.lower()))
    return ops


def response_codes(spec: Dict, path: str, method: str) -> Set[str]:
    op = spec.get("paths", {}).get(path, {}).get(method, {})
    responses = op.get("responses", {})
    return set(responses.keys())


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
