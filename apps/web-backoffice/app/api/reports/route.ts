import { NextRequest, NextResponse } from "next/server";
import { buildAuthenticatedHeaders, readAuthSession, unauthorizedJson } from "../../lib/auth_session";
import { callBackendOperationsApi } from "../../lib/operations_backend_client";

export function GET(request: NextRequest) {
  const session = readAuthSession(request);
  if (!session) {
    return unauthorizedJson();
  }

  const status = request.nextUrl.searchParams.get("status") ?? undefined;
  const query = new URLSearchParams({ tenantId: session.tenantId });

  if (status) {
    query.set("status", status);
  }

  return callBackendOperationsApi("backoffice/reports", {
    headers: buildAuthenticatedHeaders(session, "reports-list")
  }, query)
    .then(({ status: responseStatus, payload }) =>
      NextResponse.json(payload, { status: responseStatus })
    )
    .catch(() =>
      NextResponse.json(
        { error: "Failed to query reports from backend" },
        { status: 502 }
      )
    );
}
