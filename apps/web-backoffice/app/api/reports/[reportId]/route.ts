import { NextRequest, NextResponse } from "next/server";
import { callBackendOperationsApi } from "../../../lib/operations_backend_client";

export function GET(
  request: NextRequest,
  context: { params: Promise<{ reportId: string }> }
) {
  const tenantId = request.nextUrl.searchParams.get("tenantId") ?? "tenant-default";

  return context.params
    .then(({ reportId }) =>
      callBackendOperationsApi(
        `backoffice/reports/${reportId}`,
        undefined,
        undefined,
        { tenantId, correlationPrefix: "report-detail" }
      )
    )
    .then(({ status, payload }) => NextResponse.json(payload, { status }))
    .catch(() =>
      NextResponse.json(
        { error: "Failed to query report detail" },
        { status: 502 }
      )
    );
}
