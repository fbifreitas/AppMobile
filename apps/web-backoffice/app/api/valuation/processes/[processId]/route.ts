import { NextRequest, NextResponse } from "next/server";
import { buildAuthenticatedHeaders, readAuthSession, unauthorizedJson } from "../../../../lib/auth_session";
import { callBackendOperationsApi } from "../../../../lib/operations_backend_client";

export function GET(
  request: NextRequest,
  context: { params: Promise<{ processId: string }> }
) {
  const session = readAuthSession(request);
  if (!session) {
    return unauthorizedJson();
  }

  return context.params
    .then(({ processId }) =>
      callBackendOperationsApi(
        `backoffice/valuation/processes/${processId}`,
        {
          headers: buildAuthenticatedHeaders(session, "valuation-detail")
        },
        undefined,
        { tenantId: session.tenantId, actorId: String(session.userId), correlationPrefix: "valuation-detail" }
      )
    )
    .then(({ status, payload }) => NextResponse.json(payload, { status }))
    .catch(() =>
      NextResponse.json(
        { error: "Failed to query valuation process detail" },
        { status: 502 }
      )
    );
}
