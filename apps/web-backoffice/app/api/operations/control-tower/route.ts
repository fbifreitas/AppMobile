import { NextRequest, NextResponse } from "next/server";
import { buildAuthenticatedHeaders, readAuthSession, unauthorizedJson } from "../../../lib/auth_session";
import { callBackendOperationsApi } from "../../../lib/operations_backend_client";

export function GET(request: NextRequest) {
  const session = readAuthSession(request);
  if (!session) {
    return unauthorizedJson();
  }

  const tenantId = session.tenantId;
  const query = new URLSearchParams({ tenantId });

  return callBackendOperationsApi("backoffice/operations/control-tower", {
    headers: buildAuthenticatedHeaders(session, "control-tower")
  }, query, {
    tenantId,
    actorId: String(session.userId),
    correlationPrefix: "control-tower"
  })
    .then(({ status, payload }) => NextResponse.json(payload, { status }))
    .catch(() =>
      NextResponse.json(
        { error: "Failed to query control tower data from backend" },
        { status: 502 }
      )
    );
}
