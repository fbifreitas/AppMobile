import { NextRequest, NextResponse } from "next/server";
import { callBackendOperationsApi } from "../../../../lib/operations_backend_client";

export const dynamic = "force-dynamic";

export async function POST(
  request: NextRequest,
  context: { params: Promise<{ jobId: string }> }
) {
  const tenantId = request.nextUrl.searchParams.get("tenantId") ?? request.headers.get("X-Tenant-Id") ?? "tenant-default";
  const actorId = request.nextUrl.searchParams.get("actorId") ?? request.headers.get("X-Actor-Id") ?? "backoffice-operator";

  try {
    const payload = await request.json().catch(() => ({}));
    const { jobId } = await context.params;
    const response = await callBackendOperationsApi(
      `jobs/${jobId}/cancel`,
      {
        method: "POST",
        body: JSON.stringify(payload)
      },
      undefined,
      {
        tenantId,
        actorId,
        correlationPrefix: "job-cancel"
      }
    );

    return NextResponse.json(response.payload, { status: response.status });
  } catch {
    return NextResponse.json(
      { error: "Falha ao cancelar job no backend" },
      { status: 502 }
    );
  }
}
