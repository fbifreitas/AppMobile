import { NextRequest, NextResponse } from "next/server";
import { callBackendOperationsApi } from "../../lib/operations_backend_client";

export function GET(request: NextRequest) {
  const tenantId = request.nextUrl.searchParams.get("tenantId") ?? "tenant-default";
  const status = request.nextUrl.searchParams.get("status") ?? undefined;
  const query = new URLSearchParams({ tenantId });

  if (status) {
    query.set("status", status);
  }

  return callBackendOperationsApi("backoffice/reports", undefined, query)
    .then(({ status: responseStatus, payload }) =>
      NextResponse.json(payload, { status: responseStatus })
    )
    .catch(() =>
      NextResponse.json(
        { error: "Failed to query reports from backend" },
        { status: 502 }
      )
    );
}
