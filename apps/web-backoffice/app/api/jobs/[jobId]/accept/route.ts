import { NextRequest, NextResponse } from "next/server";
import { buildAuthenticatedHeaders, readAuthSession, unauthorizedJson } from "../../../../lib/auth_session";
import { callBackendOperationsApi } from "../../../../lib/operations_backend_client";

export const dynamic = "force-dynamic";

export async function POST(
  request: NextRequest,
  context: { params: { jobId: string } }
) {
  const session = readAuthSession(request);
  if (!session) {
    return unauthorizedJson();
  }

  try {
    const actorId = request.nextUrl.searchParams.get("actorId")?.trim() || String(session.userId);
    const response = await callBackendOperationsApi(
      `jobs/${context.params.jobId}/accept`,
      {
        method: "POST",
        headers: buildAuthenticatedHeaders(session, "job-accept")
      },
      undefined,
      {
        tenantId: session.tenantId,
        actorId,
        correlationPrefix: "job-accept"
      }
    );

    return NextResponse.json(response.payload, { status: response.status });
  } catch {
    return NextResponse.json(
      { error: "Falha ao aceitar job no backend" },
      { status: 502 }
    );
  }
}
