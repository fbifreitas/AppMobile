import { NextRequest, NextResponse } from "next/server";
import { buildAuthenticatedHeaders, readAuthSession, unauthorizedJson } from "../../../lib/auth_session";
import { callBackendOperationsApi } from "../../../lib/operations_backend_client";

export function GET(request: NextRequest) {
  const session = readAuthSession(request);
  if (!session) {
    return unauthorizedJson();
  }

  return callBackendOperationsApi("backoffice/intelligence/normative-matrix", {
    headers: buildAuthenticatedHeaders(session, "normative-matrix")
  }, undefined, {
    tenantId: session.tenantId,
    actorId: String(session.userId),
    correlationPrefix: "normative-matrix"
  })
    .then(({ status, payload }) => NextResponse.json(payload, { status }))
    .catch(() =>
      NextResponse.json(
        { error: "Falha ao consultar matriz normativa no backend" },
        { status: 502 }
      )
    );
}
