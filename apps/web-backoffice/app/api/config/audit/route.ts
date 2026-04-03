import { NextRequest, NextResponse } from "next/server";
import { callBackendConfigApi } from "../../../lib/config_backend_client";
import {
  canPerformConfigAction,
  getPolicyErrorMessage,
  type ActorRole
} from "../../../lib/config_policy";

export function GET(request: NextRequest) {
  const tenantId = request.nextUrl.searchParams.get("tenantId") ?? undefined;
  const limit = Number(request.nextUrl.searchParams.get("limit") ?? "20");
  const actorRole = (request.nextUrl.searchParams.get("actorRole") ?? "tenant_admin") as ActorRole;

  if (!canPerformConfigAction(actorRole, "read")) {
    return NextResponse.json({ error: getPolicyErrorMessage(actorRole, "read") }, { status: 403 });
  }

  if (!tenantId) {
    return NextResponse.json({ error: "Campo obrigatorio ausente: tenantId" }, { status: 400 });
  }

  const normalizedLimit = Number.isFinite(limit) ? Math.max(1, limit) : 20;
  const query = new URLSearchParams({ tenantId, actorRole });

  return callBackendConfigApi<{ items: unknown[]; count: number; generatedAt: string }>(
    "audit",
    undefined,
    query
  )
    .then(({ status, payload }) => {
      const items = payload.items.slice(0, normalizedLimit);

      return NextResponse.json(
        {
          items,
          count: items.length,
          generatedAt: payload.generatedAt
        },
        { status }
      );
    })
    .catch(() =>
      NextResponse.json(
        { error: "Falha ao consultar auditoria no backend" },
        { status: 502 }
      )
    );
}
