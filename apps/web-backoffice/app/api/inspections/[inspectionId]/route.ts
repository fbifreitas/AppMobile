import { NextRequest, NextResponse } from "next/server";
import { callBackendInspectionsApi } from "../../../lib/inspections_backend_client";

export function GET(
  request: NextRequest,
  context: { params: Promise<{ inspectionId: string }> }
) {
  const tenantId = request.nextUrl.searchParams.get("tenantId") ?? "tenant-default";

  return context.params
    .then(({ inspectionId }) => {
      const query = new URLSearchParams({ tenantId });
      return callBackendInspectionsApi(inspectionId, undefined, query);
    })
    .then(({ status, payload }) => NextResponse.json(payload, { status }))
    .catch(() =>
      NextResponse.json(
        { error: "Falha ao consultar detalhe da inspection no backend" },
        { status: 502 }
      )
    );
}
