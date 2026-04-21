import { NextRequest, NextResponse } from "next/server";
import { buildAuthenticatedHeaders, readAuthSession, unauthorizedJson } from "../../../../../lib/auth_session";
import { callBackendOperationsApi } from "../../../../../lib/operations_backend_client";

export async function POST(request: NextRequest) {
  const session = readAuthSession(request);
  if (!session) {
    return unauthorizedJson();
  }

  const tenantId = session.tenantId;
  const actorId = String(session.userId);

  try {
    const { status, payload } = await callBackendOperationsApi(
      "backoffice/operations/control-tower/retention/run",
      {
        method: "POST",
        headers: buildAuthenticatedHeaders(session, "control-tower-retention")
      },
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
