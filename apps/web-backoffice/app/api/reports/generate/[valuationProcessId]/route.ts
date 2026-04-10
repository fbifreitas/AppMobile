import { NextRequest, NextResponse } from "next/server";
import { buildAuthenticatedHeaders, readAuthSession, unauthorizedJson } from "../../../../lib/auth_session";
import { callBackendOperationsApi } from "../../../../lib/operations_backend_client";

export async function POST(
  request: NextRequest,
  context: { params: Promise<{ valuationProcessId: string }> }
) {
  const session = readAuthSession(request);
  if (!session) {
    return unauthorizedJson();
  }

  try {
    const body = await request.text();
    const { valuationProcessId } = await context.params;
    const { status, payload } = await callBackendOperationsApi(
      `backoffice/reports/${valuationProcessId}/generate`,
      {
        method: "POST",
        headers: buildAuthenticatedHeaders(session, "report-generate"),
        body: body.length > 0 ? body : "{}"
      },
      undefined,
      { tenantId: session.tenantId, actorId: String(session.userId), correlationPrefix: "report-generate" }
    );

    return NextResponse.json(payload, { status });
  } catch {
    return NextResponse.json(
      { error: "Failed to generate report" },
      { status: 502 }
    );
  }
}
