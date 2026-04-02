import importlib.util
import pathlib
import unittest


SCRIPT_PATH = pathlib.Path(__file__).with_name("openapi_breaking_check.py")
SPEC = importlib.util.spec_from_file_location("openapi_breaking_check", SCRIPT_PATH)
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


def build_spec(
    *,
    include_canonical_ref=True,
    canonical_required=None,
    severity_enum=None,
    include_only_parameters=False,
    required_headers=None,
    optional_headers=None,
):
    if canonical_required is None:
        canonical_required = [
            "timestamp",
            "code",
            "severity",
            "message",
            "correlationId",
            "path",
        ]

    if severity_enum is None:
        severity_enum = ["ERROR", "WARNING"]

    if required_headers is None:
        required_headers = []

    if optional_headers is None:
        optional_headers = []

    error_schema = {"type": "object", "required": canonical_required, "properties": {"code": {"type": "string"}}}
    severity_schema = {"type": "string", "enum": severity_enum}

    response_schema = (
        {"$ref": "#/components/schemas/CanonicalErrorResponse"}
        if include_canonical_ref
        else {"type": "object", "properties": {"message": {"type": "string"}}}
    )

    paths = {
        "/api/mobile/checkin-config": {
            "get": {
                "parameters": [
                    {
                        "name": header,
                        "in": "header",
                        "required": True,
                        "schema": {"type": "string"},
                    }
                    for header in required_headers
                ]
                + [
                    {
                        "name": header,
                        "in": "header",
                        "required": False,
                        "schema": {"type": "string"},
                    }
                    for header in optional_headers
                ],
                "responses": {
                    "200": {"description": "ok"},
                    "400": {
                        "description": "bad request",
                        "content": {
                            "application/json": {
                                "schema": response_schema
                            }
                        },
                    },
                }
            }
        }
    }

    if include_only_parameters:
        paths = {
            "/api/mobile/checkin-config": {
                "parameters": [
                    {
                        "name": "tenant-id",
                        "in": "header",
                        "required": True,
                        "schema": {"type": "string"},
                    }
                ]
            }
        }

    return {
        "openapi": "3.0.3",
        "info": {"title": "Test API", "version": "1.0.0"},
        "paths": paths,
        "components": {
            "schemas": {
                "CanonicalErrorResponse": error_schema,
                "ErrorSeverity": severity_schema,
                "SomeOtherSchema": {
                    "type": "object",
                    "required": ["id"],
                    "properties": {"id": {"type": "string"}, "name": {"type": "string"}},
                },
            }
        },
    }


class OpenApiBreakingCheckTests(unittest.TestCase):
    def test_ignores_non_http_path_keys(self):
        base = build_spec(include_only_parameters=True)
        curr = build_spec(include_only_parameters=True)

        failures = MODULE.check_breaking(base, curr)

        self.assertEqual([], failures)

    def test_detects_removed_operation(self):
        base = build_spec()
        curr = build_spec()
        curr["paths"] = {}

        failures = MODULE.check_breaking(base, curr)

        self.assertIn("Removed operation: GET /api/mobile/checkin-config", failures)

    def test_detects_removed_canonical_error_reference_in_4xx(self):
        base = build_spec(include_canonical_ref=True)
        curr = build_spec(include_canonical_ref=False)

        failures = MODULE.check_breaking(base, curr)

        self.assertIn(
            "Missing canonical error schema in 4xx response: GET /api/mobile/checkin-config -> 400",
            failures,
        )

    def test_does_not_require_canonical_if_base_never_had_it(self):
        base = build_spec(include_canonical_ref=False)
        curr = build_spec(include_canonical_ref=False)

        failures = MODULE.check_breaking(base, curr)

        self.assertFalse(
            any("Missing canonical error schema in 4xx response" in f for f in failures)
        )

    def test_detects_removed_canonical_required_field(self):
        base = build_spec(canonical_required=["timestamp", "code", "severity", "message", "correlationId", "path"])
        curr = build_spec(canonical_required=["timestamp", "code", "severity", "message", "correlationId"])

        failures = MODULE.check_breaking(base, curr)

        self.assertIn(
            "Removed canonical required field: components.schemas.CanonicalErrorResponse.path",
            failures,
        )

    def test_detects_removed_severity_enum_value(self):
        base = build_spec(severity_enum=["ERROR", "WARNING"])
        curr = build_spec(severity_enum=["ERROR"])

        failures = MODULE.check_breaking(base, curr)

        self.assertIn(
            "Removed error severity level: components.schemas.ErrorSeverity.WARNING",
            failures,
        )

    def test_detects_removed_required_header_parameter(self):
        base = build_spec(required_headers=["tenant-id", "correlation-id"])
        curr = build_spec(required_headers=["tenant-id"])

        failures = MODULE.check_breaking(base, curr)

        self.assertIn(
            "Removed required header parameter: GET /api/mobile/checkin-config -> correlation-id",
            failures,
        )

    def test_does_not_fail_when_only_optional_header_is_removed(self):
        base = build_spec(optional_headers=["x-debug-mode"])
        curr = build_spec()

        failures = MODULE.check_breaking(base, curr)

        self.assertFalse(
            any("Removed required header parameter" in f for f in failures)
        )


if __name__ == "__main__":
    unittest.main()
