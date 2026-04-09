import { NextRequest, NextResponse } from "next/server";
import { callBackendOperationsApi } from "../../../lib/operations_backend_client";

export function GET(request: NextRequest) {
  const tenantId = request.nextUrl.searchParams.get("tenantId") ?? "tenant-default";
  const query = new URLSearchParams({ tenantId });

  return callBackendOperationsApi("backoffice/operations/control-tower", undefined, query, {
    tenantId,
    correlationPrefix: "control-tower"
  })
    .then(({ status, payload }) => NextResponse.json(payload, { status }))
    .catch(() =>
      NextResponse.json(
        { error: "Failed to query control tower data from backend" },
        { status: 502 }
      )
    );
}
