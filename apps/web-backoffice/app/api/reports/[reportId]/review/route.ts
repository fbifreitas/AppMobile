import { NextRequest, NextResponse } from "next/server";
import { callBackendOperationsApi } from "../../../../lib/operations_backend_client";

export async function POST(
  request: NextRequest,
  context: { params: Promise<{ reportId: string }> }
) {
  const tenantId = request.nextUrl.searchParams.get("tenantId") ?? "tenant-default";
  const actorId = request.headers.get("X-Actor-Id") ?? "backoffice-operator";

  try {
    const body = await request.json();
    const { reportId } = await context.params;
    const { status, payload } = await callBackendOperationsApi(
      `backoffice/reports/${reportId}/review`,
      {
        method: "POST",
        body: JSON.stringify(body)
      },
      undefined,
      { tenantId, actorId, correlationPrefix: "report-review" }
    );

    return NextResponse.json(payload, { status });
  } catch {
    return NextResponse.json(
      { error: "Failed to review report" },
      { status: 502 }
    );
  }
}
