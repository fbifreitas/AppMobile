import { NextRequest, NextResponse } from "next/server";
import { buildAuthenticatedHeaders, readAuthSession, unauthorizedJson } from "../../../../../lib/auth_session";
import { callBackendOperationsApi } from "../../../../../lib/operations_backend_client";

type RouteContext = {
  params: {
    tenantId: string;
  };
};

export function GET(request: NextRequest, context: RouteContext) {
  const session = readAuthSession(request);
  if (!session) {
    return unauthorizedJson();
  }

  const query = new URLSearchParams({ actorRole: "platform_admin" });
  return callBackendOperationsApi(`backoffice/platform/tenants/${context.params.tenantId}/license`, {
    headers: buildAuthenticatedHeaders(session, "platform-license", {
      "X-Actor-Role": "platform_admin"
    })
  }, query, {
    tenantId: session.tenantId,
    actorId: String(session.userId),
    correlationPrefix: "platform-license"
  })
    .then(({ status, payload }) => NextResponse.json(payload, { status }))
    .catch(() => NextResponse.json({ error: "Failed to query tenant license" }, { status: 502 }));
}

export async function PUT(request: NextRequest, context: RouteContext) {
  const session = readAuthSession(request);
  if (!session) {
    return unauthorizedJson();
  }

  const payload = await request.json();
  const query = new URLSearchParams({ actorRole: "platform_admin" });
  return callBackendOperationsApi(`backoffice/platform/tenants/${context.params.tenantId}/license`, {
    method: "PUT",
    headers: buildAuthenticatedHeaders(session, "platform-license", {
      "X-Actor-Role": "platform_admin"
    }),
    body: JSON.stringify(payload)
  }, query, {
    tenantId: session.tenantId,
    actorId: String(session.userId),
    correlationPrefix: "platform-license"
  })
    .then(({ status, payload: body }) => NextResponse.json(body, { status }))
    .catch(() => NextResponse.json({ error: "Failed to update tenant license" }, { status: 502 }));
}
