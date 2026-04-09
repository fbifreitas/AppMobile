import { NextRequest, NextResponse } from "next/server";
import { callBackendOperationsApi } from "../../../../../lib/operations_backend_client";

export async function POST(request: NextRequest) {
  const tenantId = request.nextUrl.searchParams.get("tenantId") ?? "tenant-default";
  const actorId = request.headers.get("X-Actor-Id") ?? "backoffice-operator";

  try {
    const { status, payload } = await callBackendOperationsApi(
      "backoffice/operations/control-tower/retention/run",
      { method: "POST" },
      new URLSearchParams({ tenantId }),
      { tenantId, actorId, correlationPrefix: "control-tower-retention" }
    );

    return NextResponse.json(payload, { status });
  } catch {
    return NextResponse.json(
      { error: "Failed to run control tower retention cleanup" },
      { status: 502 }
    );
  }
}
