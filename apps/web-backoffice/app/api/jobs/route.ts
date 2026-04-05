import { NextRequest, NextResponse } from "next/server";
import { callBackendOperationsApi } from "../../lib/operations_backend_client";

export const dynamic = "force-dynamic";

export function GET(request: NextRequest) {
  const tenantId = request.nextUrl.searchParams.get("tenantId") ?? request.headers.get("X-Tenant-Id") ?? "tenant-default";
  const actorId = request.nextUrl.searchParams.get("actorId") ?? request.headers.get("X-Actor-Id") ?? "backoffice-operator";
  const status = request.nextUrl.searchParams.get("status") ?? undefined;
  const page = request.nextUrl.searchParams.get("page") ?? "0";
  const size = request.nextUrl.searchParams.get("size") ?? "20";

  const query = new URLSearchParams({ page, size });
  if (status) {
    query.set("status", status);
  }

  return callBackendOperationsApi("jobs", undefined, query, {
    tenantId,
    actorId,
    correlationPrefix: "jobs-list"
  })
    .then(({ status: responseStatus, payload }) =>
      NextResponse.json(payload, { status: responseStatus })
    )
    .catch(() =>
      NextResponse.json(
        { error: "Falha ao consultar jobs no backend" },
        { status: 502 }
      )
    );
}
