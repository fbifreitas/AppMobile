import { NextRequest, NextResponse } from "next/server";
import { buildAuthenticatedHeaders, readAuthSession, unauthorizedJson } from "../../../../lib/auth_session";
import { callBackendOperationsApi } from "../../../../lib/operations_backend_client";

export function POST(request: NextRequest) {
  const session = readAuthSession(request);
  if (!session) {
    return unauthorizedJson();
  }

  return callBackendOperationsApi("backoffice/intelligence/reference-profiles/rebuild", {
    method: "POST",
    headers: buildAuthenticatedHeaders(session, "reference-profiles-rebuild")
  }, undefined, {
    tenantId: session.tenantId,
    actorId: String(session.userId),
    correlationPrefix: "reference-profiles-rebuild"
  })
    .then(({ status, payload }) => NextResponse.json(payload, { status }))
    .catch(() =>
      NextResponse.json(
        { error: "Falha ao reconstruir perfis de referencia no backend" },
        { status: 502 }
      )
    );
}
