import { NextRequest, NextResponse } from "next/server";
import { buildAuthenticatedHeaders, readAuthSession, unauthorizedJson } from "../../../../../lib/auth_session";
import { callBackendOperationsApi } from "../../../../../lib/operations_backend_client";

export async function POST(
  request: NextRequest,
  context: { params: Promise<{ processId: string }> }
) {
  const session = readAuthSession(request);
  if (!session) {
    return unauthorizedJson();
  }

  try {
    const body = await request.json();
    const { processId } = await context.params;
    const { status, payload } = await callBackendOperationsApi(
      `backoffice/valuation/processes/${processId}/validate-intake`,
      {
        method: "POST",
        headers: buildAuthenticatedHeaders(session, "intake-validation"),
        body: JSON.stringify(body)
      },
      undefined,
      { tenantId: session.tenantId, actorId: String(session.userId), correlationPrefix: "intake-validation" }
    );

    return NextResponse.json(payload, { status });
  } catch {
    return NextResponse.json(
      { error: "Failed to validate intake" },
      { status: 502 }
    );
  }
}
