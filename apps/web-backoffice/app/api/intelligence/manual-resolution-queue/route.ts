import { NextRequest, NextResponse } from "next/server";
import { buildAuthenticatedHeaders, readAuthSession, unauthorizedJson } from "../../../lib/auth_session";
import { callBackendOperationsApi } from "../../../lib/operations_backend_client";

export function GET(request: NextRequest) {
  const session = readAuthSession(request);
  if (!session) {
    return unauthorizedJson();
  }

  const limit = request.nextUrl.searchParams.get("limit") ?? "20";
  const query = new URLSearchParams({ limit });

  return callBackendOperationsApi("backoffice/intelligence/manual-resolution-queue", {
    headers: buildAuthenticatedHeaders(session, "manual-resolution-queue")
  }, query, {
    tenantId: session.tenantId,
    actorId: String(session.userId),
    correlationPrefix: "manual-resolution-queue"
  })
    .then(({ status, payload }) => NextResponse.json(payload, { status }))
    .catch(() =>
      NextResponse.json(
        { error: "Falha ao consultar fila de resolucao manual no backend" },
        { status: 502 }
      )
    );
}
