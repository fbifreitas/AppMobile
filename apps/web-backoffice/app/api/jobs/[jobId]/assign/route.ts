import { NextRequest, NextResponse } from "next/server";
import { buildAuthenticatedHeaders, readAuthSession, unauthorizedJson } from "../../../../lib/auth_session";
import { callBackendOperationsApi } from "../../../../lib/operations_backend_client";

export const dynamic = "force-dynamic";

export async function POST(
  request: NextRequest,
  context: { params: Promise<{ jobId: string }> }
) {
  const session = readAuthSession(request);
  if (!session) {
    return unauthorizedJson();
  }

  try {
    const payload = await request.json();
    const { jobId } = await context.params;
    const response = await callBackendOperationsApi(
      `jobs/${jobId}/assign`,
      {
        method: "POST",
        headers: buildAuthenticatedHeaders(session, "job-assign"),
        body: JSON.stringify(payload)
      },
      undefined,
      {
        tenantId: session.tenantId,
        actorId: String(session.userId),
        correlationPrefix: "job-assign"
      }
    );

    return NextResponse.json(response.payload, { status: response.status });
  } catch {
    return NextResponse.json(
      { error: "Falha ao atribuir job no backend" },
      { status: 502 }
    );
  }
}
