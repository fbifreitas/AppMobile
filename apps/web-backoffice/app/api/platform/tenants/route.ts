import { NextRequest, NextResponse } from "next/server";
import { buildAuthenticatedHeaders, readAuthSession, requirePlatformAdmin, unauthorizedJson } from "../../../lib/auth_session";
import { callBackendOperationsApi } from "../../../lib/operations_backend_client";

export function GET(request: NextRequest) {
  const session = readAuthSession(request);
  if (!session) {
    return unauthorizedJson();
  }
  const forbidden = requirePlatformAdmin(session);
  if (forbidden) {
    return forbidden;
  }

  const query = new URLSearchParams({ actorRole: "platform_admin" });
  const q = request.nextUrl.searchParams.get("q");
  const status = request.nextUrl.searchParams.get("status");

  if (q) {
    query.set("q", q);
  }
  if (status) {
    query.set("status", status);
  }

  return callBackendOperationsApi("backoffice/platform/tenants", {
    headers: buildAuthenticatedHeaders(session, "platform-tenants", {
      "X-Actor-Role": "platform_admin"
    })
  }, query, {
    tenantId: session.tenantId,
    actorId: String(session.userId),
    correlationPrefix: "platform-tenants"
  })
    .then(({ status: responseStatus, payload }) => NextResponse.json(payload, { status: responseStatus }))
    .catch(() => NextResponse.json({ error: "Failed to query platform tenants" }, { status: 502 }));
}
