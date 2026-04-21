import { NextRequest, NextResponse } from "next/server";
import { buildAuthenticatedHeaders, readAuthSession, unauthorizedJson } from "../../../../../../lib/auth_session";
import { callBackendOperationsApi } from "../../../../../../lib/operations_backend_client";

export function POST(
  request: NextRequest,
  context: { params: { caseId: string } }
) {
  const session = readAuthSession(request);
  if (!session) {
    return unauthorizedJson();
  }

  const { caseId } = context.params;

  return callBackendOperationsApi(`backoffice/intelligence/cases/${caseId}/enrichment/trigger`, {
    method: "POST",
    headers: buildAuthenticatedHeaders(session, "trigger-enrichment")
  }, undefined, {
    tenantId: session.tenantId,
    actorId: String(session.userId),
    correlationPrefix: "trigger-enrichment"
  })
    .then(({ status, payload }) => NextResponse.json(payload, { status }))
    .catch(() =>
      NextResponse.json(
        { error: "Falha ao disparar enrichment no backend" },
        { status: 502 }
      )
    );
}
