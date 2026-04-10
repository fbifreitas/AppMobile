import { NextRequest, NextResponse } from "next/server";
import { buildAuthenticatedHeaders, readAuthSession, unauthorizedJson } from "../../lib/auth_session";
import { callBackendInspectionsApi } from "../../lib/inspections_backend_client";

export function GET(request: NextRequest) {
  const session = readAuthSession(request);
  if (!session) {
    return unauthorizedJson();
  }

  const status = request.nextUrl.searchParams.get("status") ?? undefined;
  const from = request.nextUrl.searchParams.get("from") ?? undefined;
  const to = request.nextUrl.searchParams.get("to") ?? undefined;
  const vistoriadorId = request.nextUrl.searchParams.get("vistoriadorId") ?? undefined;
  const page = request.nextUrl.searchParams.get("page") ?? "0";
  const size = request.nextUrl.searchParams.get("size") ?? "20";

  const query = new URLSearchParams({ tenantId: session.tenantId, page, size });

  if (status) query.set("status", status);
  if (from) query.set("from", from);
  if (to) query.set("to", to);
  if (vistoriadorId) query.set("vistoriadorId", vistoriadorId);

  return callBackendInspectionsApi("", {
    headers: buildAuthenticatedHeaders(session, "inspections-list")
  }, query)
    .then(({ status: responseStatus, payload }) =>
      NextResponse.json(payload, { status: responseStatus })
    )
    .catch(() =>
      NextResponse.json(
        { error: "Falha ao consultar inspections no backend" },
        { status: 502 }
      )
    );
}
