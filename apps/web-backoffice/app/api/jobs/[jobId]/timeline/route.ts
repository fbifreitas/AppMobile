import { NextRequest, NextResponse } from "next/server";
import { callBackendOperationsApi } from "../../../../lib/operations_backend_client";

export const dynamic = "force-dynamic";

export function GET(
  request: NextRequest,
  context: { params: Promise<{ jobId: string }> }
) {
  const tenantId = request.nextUrl.searchParams.get("tenantId") ?? request.headers.get("X-Tenant-Id") ?? "tenant-default";
  const actorId = request.nextUrl.searchParams.get("actorId") ?? request.headers.get("X-Actor-Id") ?? "backoffice-operator";

  return context.params
    .then(({ jobId }) =>
      callBackendOperationsApi(`jobs/${jobId}/timeline`, undefined, undefined, {
        tenantId,
        actorId,
        correlationPrefix: "job-timeline"
      })
    )
    .then(({ status, payload }) => NextResponse.json(payload, { status }))
    .catch(() =>
      NextResponse.json(
        { error: "Falha ao consultar timeline do job no backend" },
        { status: 502 }
      )
    );
}
