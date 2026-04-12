import { NextRequest, NextResponse } from "next/server";
import { buildAuthenticatedHeaders, readAuthSession, unauthorizedJson } from "../../../lib/auth_session";
import { callBackendOperationsApi } from "../../../lib/operations_backend_client";

export const dynamic = "force-dynamic";

export function GET(
  request: NextRequest,
  context: { params: { jobId: string } }
) {
  const session = readAuthSession(request);
  if (!session) {
    return unauthorizedJson();
  }

  return callBackendOperationsApi(`jobs/${context.params.jobId}`, {
      headers: buildAuthenticatedHeaders(session, "job-detail")
    }, undefined, {
      tenantId: session.tenantId,
      actorId: String(session.userId),
      correlationPrefix: "job-detail"
    })
    .then(({ status, payload }) => NextResponse.json(payload, { status }))
    .catch(() =>
      NextResponse.json(
        { error: "Falha ao consultar detalhe do job no backend" },
        { status: 502 }
      )
    );
}
