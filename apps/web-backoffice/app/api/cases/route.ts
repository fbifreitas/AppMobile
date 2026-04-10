import { NextRequest, NextResponse } from "next/server";
import { buildAuthenticatedHeaders, readAuthSession, unauthorizedJson } from "../../lib/auth_session";
import { callBackendOperationsApi } from "../../lib/operations_backend_client";

export const dynamic = "force-dynamic";

export async function POST(request: NextRequest) {
  const session = readAuthSession(request);
  if (!session) {
    return unauthorizedJson();
  }

  try {
    const payload = await request.json();
    const response = await callBackendOperationsApi(
      "cases",
      {
        method: "POST",
        headers: buildAuthenticatedHeaders(session, "case-create"),
        body: JSON.stringify(payload)
      },
      undefined,
      {
        tenantId: session.tenantId,
        actorId: String(session.userId),
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
