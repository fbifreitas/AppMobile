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

  return callBackendOperationsApi(`backoffice/platform/tenants/${context.params.tenantId}/admin-handoff`, {
    headers: buildAuthenticatedHeaders(session, "platform-admin-handoff", {
      "X-Actor-Role": "platform_admin"
    })
  }, new URLSearchParams({ actorRole: "platform_admin" }), {
    tenantId: session.tenantId,
    actorId: String(session.userId),
    correlationPrefix: "platform-admin-handoff"
  })
    .then(({ status, payload }) => NextResponse.json(payload, { status }))
    .catch(() => NextResponse.json({ error: "Failed to query tenant admin handoff" }, { status: 502 }));
}

export async function PUT(request: NextRequest, context: RouteContext) {
  const session = readAuthSession(request);
  if (!session) {
    return unauthorizedJson();
  }

  const payload = await request.json();
  return callBackendOperationsApi(`backoffice/platform/tenants/${context.params.tenantId}/admin-handoff`, {
    method: "PUT",
    headers: buildAuthenticatedHeaders(session, "platform-admin-handoff", {
      "X-Actor-Role": "platform_admin"
    }),
    body: JSON.stringify(payload)
  }, new URLSearchParams({ actorRole: "platform_admin" }), {
    tenantId: session.tenantId,
    actorId: String(session.userId),
    correlationPrefix: "platform-admin-handoff"
  })
    .then(({ status, payload: body }) => NextResponse.json(body, { status }))
    .catch(() => NextResponse.json({ error: "Failed to update tenant admin handoff" }, { status: 502 }));
}
