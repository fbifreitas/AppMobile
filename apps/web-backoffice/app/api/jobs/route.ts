import { NextRequest, NextResponse } from "next/server";
import { buildAuthenticatedHeaders, readAuthSession, unauthorizedJson } from "../../lib/auth_session";
import { callBackendOperationsApi } from "../../lib/operations_backend_client";

export const dynamic = "force-dynamic";

export function GET(request: NextRequest) {
  const session = readAuthSession(request);
  if (!session) {
    return unauthorizedJson();
  }

  const status = request.nextUrl.searchParams.get("status") ?? undefined;
  const page = request.nextUrl.searchParams.get("page") ?? "0";
  const size = request.nextUrl.searchParams.get("size") ?? "20";

  const query = new URLSearchParams({ page, size });
  if (status) {
    query.set("status", status);
  }

  return callBackendOperationsApi("jobs", {
    headers: buildAuthenticatedHeaders(session, "jobs-list")
  }, query, {
    tenantId: session.tenantId,
    actorId: String(session.userId),
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
