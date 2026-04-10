import { NextRequest, NextResponse } from "next/server";
import { buildAuthenticatedHeaders, readAuthSession, unauthorizedJson } from "../../../lib/auth_session";
import { callBackendOperationsApi } from "../../../lib/operations_backend_client";

export function GET(request: NextRequest) {
  const session = readAuthSession(request);
  if (!session) {
    return unauthorizedJson();
  }

  const status = request.nextUrl.searchParams.get("status") ?? undefined;
  const query = new URLSearchParams({ tenantId: session.tenantId });

  if (status) {
    query.set("status", status);
  }

  return callBackendOperationsApi("backoffice/valuation/processes", {
    headers: buildAuthenticatedHeaders(session, "valuation-list")
  }, query)
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
  const session = readAuthSession(request);
  if (!session) {
    return unauthorizedJson();
  }

  try {
    const body = await request.json();
    const { status, payload } = await callBackendOperationsApi(
      "backoffice/valuation/processes",
      {
        method: "POST",
        headers: buildAuthenticatedHeaders(session, "valuation-create"),
        body: JSON.stringify(body)
      },
      undefined,
      { tenantId: session.tenantId, actorId: String(session.userId), correlationPrefix: "valuation-create" }
    );

    return NextResponse.json(payload, { status });
  } catch {
    return NextResponse.json(
      { error: "Failed to create valuation process" },
      { status: 502 }
    );
  }
}
