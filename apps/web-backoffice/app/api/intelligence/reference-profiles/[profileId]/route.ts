import { NextRequest, NextResponse } from "next/server";
import { buildAuthenticatedHeaders, readAuthSession, unauthorizedJson } from "../../../../lib/auth_session";
import { callBackendOperationsApi } from "../../../../lib/operations_backend_client";

type Params = {
  params: { profileId: string };
};

export async function PUT(request: NextRequest, { params }: Params) {
  const session = readAuthSession(request);
  if (!session) {
    return unauthorizedJson();
  }

  const body = await request.text();

  return callBackendOperationsApi(`backoffice/intelligence/reference-profiles/${params.profileId}`, {
    method: "PUT",
    headers: {
      ...buildAuthenticatedHeaders(session, "reference-profiles-update"),
      "Content-Type": "application/json"
    },
    body
  }, undefined, {
    tenantId: session.tenantId,
    actorId: String(session.userId),
    correlationPrefix: "reference-profiles-update"
  })
    .then(({ status, payload }) => NextResponse.json(payload, { status }))
    .catch(() =>
      NextResponse.json(
        { error: "Falha ao atualizar perfil de referencia no backend" },
        { status: 502 }
      )
    );
}
