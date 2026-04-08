import { NextRequest, NextResponse } from "next/server";
import { callBackendOperationsApi } from "../../../../lib/operations_backend_client";

export function GET(
  request: NextRequest,
  context: { params: Promise<{ processId: string }> }
) {
  const tenantId = request.nextUrl.searchParams.get("tenantId") ?? "tenant-default";

  return context.params
    .then(({ processId }) =>
      callBackendOperationsApi(
        `backoffice/valuation/processes/${processId}`,
        undefined,
        undefined,
        { tenantId, correlationPrefix: "valuation-detail" }
      )
    )
    .then(({ status, payload }) => NextResponse.json(payload, { status }))
    .catch(() =>
      NextResponse.json(
        { error: "Failed to query valuation process detail" },
        { status: 502 }
      )
    );
}
