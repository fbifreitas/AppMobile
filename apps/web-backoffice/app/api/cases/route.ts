import { NextRequest, NextResponse } from "next/server";
import { callBackendOperationsApi } from "../../lib/operations_backend_client";

export const dynamic = "force-dynamic";

export async function POST(request: NextRequest) {
  const tenantId = request.nextUrl.searchParams.get("tenantId") ?? request.headers.get("X-Tenant-Id") ?? "tenant-default";
  const actorId = request.nextUrl.searchParams.get("actorId") ?? request.headers.get("X-Actor-Id") ?? "backoffice-operator";

  try {
    const payload = await request.json();
    const response = await callBackendOperationsApi(
      "cases",
      {
        method: "POST",
        body: JSON.stringify(payload)
      },
      undefined,
      {
        tenantId,
        actorId,
        correlationPrefix: "case-create"
      }
    );

    return NextResponse.json(response.payload, { status: response.status });
  } catch {
    return NextResponse.json(
      { error: "Falha ao criar case no backend" },
      { status: 502 }
    );
  }
}
