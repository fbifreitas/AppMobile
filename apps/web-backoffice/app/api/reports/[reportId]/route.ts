import { NextRequest, NextResponse } from "next/server";
import { buildAuthenticatedHeaders, readAuthSession, unauthorizedJson } from "../../../lib/auth_session";
import { callBackendOperationsApi } from "../../../lib/operations_backend_client";

export function GET(
  request: NextRequest,
  context: { params: { reportId: string } }
) {
  const session = readAuthSession(request);
  if (!session) {
    return unauthorizedJson();
  }

  return callBackendOperationsApi(
      `backoffice/reports/${context.params.reportId}`,
      {
        headers: buildAuthenticatedHeaders(session, "report-detail")
      },
      new URLSearchParams({ tenantId: session.tenantId }),
      { tenantId: session.tenantId, actorId: String(session.userId), correlationPrefix: "report-detail" }
    )
    .then(({ status, payload }) => NextResponse.json(payload, { status }))
    .catch(() =>
      NextResponse.json(
        { error: "Failed to query report detail" },
        { status: 502 }
      )
    );
}
