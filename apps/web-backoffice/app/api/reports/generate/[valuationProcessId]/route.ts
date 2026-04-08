import { NextRequest, NextResponse } from "next/server";
import { callBackendOperationsApi } from "../../../../lib/operations_backend_client";

export async function POST(
  request: NextRequest,
  context: { params: Promise<{ valuationProcessId: string }> }
) {
  const tenantId = request.nextUrl.searchParams.get("tenantId") ?? "tenant-default";
  const actorId = request.headers.get("X-Actor-Id") ?? "backoffice-operator";

  try {
    const body = await request.text();
    const { valuationProcessId } = await context.params;
    const { status, payload } = await callBackendOperationsApi(
      `backoffice/reports/${valuationProcessId}/generate`,
      {
        method: "POST",
        body: body.length > 0 ? body : "{}"
      },
      undefined,
      { tenantId, actorId, correlationPrefix: "report-generate" }
    );

    return NextResponse.json(payload, { status });
  } catch {
    return NextResponse.json(
      { error: "Failed to generate report" },
      { status: 502 }
    );
  }
}
