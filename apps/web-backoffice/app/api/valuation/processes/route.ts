import { NextRequest, NextResponse } from "next/server";
import { callBackendOperationsApi } from "../../../lib/operations_backend_client";

export function GET(request: NextRequest) {
  const tenantId = request.nextUrl.searchParams.get("tenantId") ?? "tenant-default";
  const status = request.nextUrl.searchParams.get("status") ?? undefined;
  const query = new URLSearchParams({ tenantId });

  if (status) {
    query.set("status", status);
  }

  return callBackendOperationsApi("backoffice/valuation/processes", undefined, query)
    .then(({ status: responseStatus, payload }) =>
      NextResponse.json(payload, { status: responseStatus })
    )
    .catch(() =>
      NextResponse.json(
        { error: "Failed to query valuation processes from backend" },
        { status: 502 }
      )
    );
}

export async function POST(request: NextRequest) {
  const tenantId = request.nextUrl.searchParams.get("tenantId") ?? "tenant-default";
  const actorId = request.headers.get("X-Actor-Id") ?? "backoffice-operator";

  try {
    const body = await request.json();
    const { status, payload } = await callBackendOperationsApi(
      "backoffice/valuation/processes",
      {
        method: "POST",
        body: JSON.stringify(body)
      },
      undefined,
      { tenantId, actorId, correlationPrefix: "valuation-create" }
    );

    return NextResponse.json(payload, { status });
  } catch {
    return NextResponse.json(
      { error: "Failed to create valuation process" },
      { status: 502 }
    );
  }
}
