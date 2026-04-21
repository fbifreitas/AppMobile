import { NextRequest, NextResponse } from "next/server";
import { buildAuthenticatedHeaders, readAuthSession, unauthorizedJson } from "../../../../../../lib/auth_session";
import { callBackendOperationsApi } from "../../../../../../lib/operations_backend_client";

export async function POST(
  request: NextRequest,
  context: { params: { caseId: string } }
) {
  const session = readAuthSession(request);
  if (!session) {
    return unauthorizedJson();
  }

  const { caseId } = context.params;
  const body = await request.text();

  return callBackendOperationsApi(`backoffice/intelligence/cases/${caseId}/manual-resolution/subtype`, {
    method: "POST",
    headers: {
      ...buildAuthenticatedHeaders(session, "manual-subtype-resolution"),
      "Content-Type": "application/json"
    },
    body
  }, undefined, {
    tenantId: session.tenantId,
    actorId: String(session.userId),
    correlationPrefix: "manual-subtype-resolution"
  })
    .then(({ status, payload }) => NextResponse.json(payload, { status }))
    .catch(() =>
      NextResponse.json(
        { error: "Falha ao aplicar resolucao manual de subtipo no backend" },
        { status: 502 }
      )
    );
}
