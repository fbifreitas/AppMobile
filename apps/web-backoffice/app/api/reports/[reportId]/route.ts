import { NextRequest, NextResponse } from "next/server";
import { buildAuthenticatedHeaders, readAuthSession, unauthorizedJson } from "../../../lib/auth_session";
import { callBackendOperationsApi } from "../../../lib/operations_backend_client";

export function GET(
  request: NextRequest,
  context: { params: Promise<{ reportId: string }> }
) {
  const session = readAuthSession(request);
  if (!session) {
    return unauthorizedJson();
  }

  return context.params
    .then(({ reportId }) =>
      callBackendOperationsApi(
        `backoffice/reports/${reportId}`,
        {
          headers: buildAuthenticatedHeaders(session, "report-detail")
        },
        undefined,
        { tenantId: session.tenantId, actorId: String(session.userId), correlationPrefix: "report-detail" }
      )
    )
    .then(({ status, payload }) => NextResponse.json(payload, { status }))
    .catch(() =>
      NextResponse.json(
        { error: "Failed to query report detail" },
        { status: 502 }
      )
    );
}
