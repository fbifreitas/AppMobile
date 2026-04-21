import { NextRequest, NextResponse } from "next/server";
import { buildAuthenticatedHeaders, readAuthSession, unauthorizedJson } from "../../../lib/auth_session";
import { callBackendInspectionsApi } from "../../../lib/inspections_backend_client";

export function GET(
  request: NextRequest,
  context: { params: { inspectionId: string } }
) {
  const session = readAuthSession(request);
  if (!session) {
    return unauthorizedJson();
  }

  const { inspectionId } = context.params;
  const query = new URLSearchParams({ tenantId: session.tenantId });

  return callBackendInspectionsApi(inspectionId, {
    headers: buildAuthenticatedHeaders(session, "inspection-detail")
  }, query)
    .then(({ status, payload }) => NextResponse.json(payload, { status }))
    .catch(() =>
      NextResponse.json(
        { error: "Falha ao consultar detalhe da inspection no backend" },
        { status: 502 }
      )
    );
}

export async function POST(
  request: NextRequest,
  context: { params: { inspectionId: string } }
) {
  const session = readAuthSession(request);
  if (!session) {
    return unauthorizedJson();
  }

  const { inspectionId } = context.params;
  const query = new URLSearchParams({ tenantId: session.tenantId });

  try {
    const body = await request.json();
    const { status, payload } = await callBackendInspectionsApi(
      `${inspectionId}/manual-classification`,
      {
        method: "POST",
        headers: buildAuthenticatedHeaders(session, "inspection-manual-classification"),
        body: JSON.stringify(body)
      },
      query
    );
    return NextResponse.json(payload, { status });
  } catch {
    return NextResponse.json(
      { error: "Falha ao salvar classificacao manual da inspection no backend" },
      { status: 502 }
    );
  }
}
