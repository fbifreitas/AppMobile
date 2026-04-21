import { NextRequest, NextResponse } from "next/server";
import { buildAuthenticatedHeaders, readAuthSession, unauthorizedJson } from "../../../../../lib/auth_session";
import { callBackendOperationsApi } from "../../../../../lib/operations_backend_client";

type Params = {
  params: { profileId: string };
};

export function POST(request: NextRequest, { params }: Params) {
  const session = readAuthSession(request);
  if (!session) {
    return unauthorizedJson();
  }

  return callBackendOperationsApi(`backoffice/intelligence/reference-profiles/${params.profileId}/activate`, {
    method: "POST",
    headers: buildAuthenticatedHeaders(session, "reference-profiles-activate")
  }, undefined, {
    tenantId: session.tenantId,
    actorId: String(session.userId),
    correlationPrefix: "reference-profiles-activate"
  })
    .then(({ status, payload }) => NextResponse.json(payload, { status }))
    .catch(() =>
      NextResponse.json(
        { error: "Falha ao ativar perfil de referencia no backend" },
        { status: 502 }
      )
    );
}
