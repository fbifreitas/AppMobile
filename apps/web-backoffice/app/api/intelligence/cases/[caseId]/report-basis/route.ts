import { NextRequest, NextResponse } from "next/server";
import { buildAuthenticatedHeaders, readAuthSession, unauthorizedJson } from "../../../../../lib/auth_session";
import { callBackendOperationsApi } from "../../../../../lib/operations_backend_client";

export function GET(
  request: NextRequest,
  context: { params: { caseId: string } }
) {
  const session = readAuthSession(request);
  if (!session) {
    return unauthorizedJson();
  }

  const { caseId } = context.params;

  return callBackendOperationsApi(`backoffice/intelligence/cases/${caseId}/report-basis`, {
    headers: buildAuthenticatedHeaders(session, "report-basis")
  }, undefined, {
    tenantId: session.tenantId,
    actorId: String(session.userId),
    correlationPrefix: "report-basis"
  })
    .then(({ status, payload }) => NextResponse.json(payload, { status }))
    .catch(() =>
      NextResponse.json(
        { error: "Falha ao consultar report basis no backend" },
        { status: 502 }
      )
    );
}
