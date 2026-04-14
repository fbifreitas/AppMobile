import { NextRequest, NextResponse } from "next/server";
import { buildAuthenticatedHeaders, readAuthSession, unauthorizedJson } from "../../../../lib/auth_session";
import { callBackendOperationsApi } from "../../../../lib/operations_backend_client";

export async function POST(
  request: NextRequest,
  context: { params: { reportId: string } }
) {
  const session = readAuthSession(request);
  if (!session) {
    return unauthorizedJson();
  }

  try {
    const body = await request.json();
    const { reportId } = context.params;
    const { status, payload } = await callBackendOperationsApi(
      `backoffice/reports/${reportId}/review`,
      {
        method: "POST",
        headers: buildAuthenticatedHeaders(session, "report-review"),
        body: JSON.stringify(body)
      },
      new URLSearchParams({ tenantId: session.tenantId }),
      { tenantId: session.tenantId, actorId: String(session.userId), correlationPrefix: "report-review" }
    );

    return NextResponse.json(payload, { status });
  } catch {
    return NextResponse.json(
      { error: "Failed to review report" },
      { status: 502 }
    );
  }
}
