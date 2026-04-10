import { NextRequest, NextResponse } from "next/server";
import { buildAuthenticatedHeaders, readAuthSession, unauthorizedJson } from "../../../../lib/auth_session";
import { callBackendOperationsApi } from "../../../../lib/operations_backend_client";

export const dynamic = "force-dynamic";

export function GET(
  request: NextRequest,
  context: { params: Promise<{ jobId: string }> }
) {
  const session = readAuthSession(request);
  if (!session) {
    return unauthorizedJson();
  }

  return context.params
    .then(({ jobId }) =>
      callBackendOperationsApi(`jobs/${jobId}/timeline`, {
        headers: buildAuthenticatedHeaders(session, "job-timeline")
      }, undefined, {
        tenantId: session.tenantId,
        actorId: String(session.userId),
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
