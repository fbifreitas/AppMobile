import { NextRequest, NextResponse } from "next/server";
import { buildAuthenticatedHeaders, readAuthSession, unauthorizedJson } from "../../../lib/auth_session";
import { callBackendOperationsApi } from "../../../lib/operations_backend_client";

export function GET(request: NextRequest) {
  const session = readAuthSession(request);
  if (!session) {
    return unauthorizedJson();
  }

  return callBackendOperationsApi("backoffice/intelligence/reference-profiles", {
    headers: buildAuthenticatedHeaders(session, "reference-profiles")
  }, undefined, {
    tenantId: session.tenantId,
    actorId: String(session.userId),
    correlationPrefix: "reference-profiles"
  })
    .then(({ status, payload }) => NextResponse.json(payload, { status }))
    .catch(() =>
      NextResponse.json(
        { error: "Falha ao consultar perfis de referencia no backend" },
        { status: 502 }
      )
    );
}

export async function POST(request: NextRequest) {
  const session = readAuthSession(request);
  if (!session) {
    return unauthorizedJson();
  }

  const body = await request.text();

  return callBackendOperationsApi("backoffice/intelligence/reference-profiles", {
    method: "POST",
    headers: {
      ...buildAuthenticatedHeaders(session, "reference-profiles-create"),
      "Content-Type": "application/json"
    },
    body
  }, undefined, {
    tenantId: session.tenantId,
    actorId: String(session.userId),
    correlationPrefix: "reference-profiles-create"
  })
    .then(({ status, payload }) => NextResponse.json(payload, { status }))
    .catch(() =>
      NextResponse.json(
        { error: "Falha ao criar perfil de referencia no backend" },
        { status: 502 }
      )
    );
}
