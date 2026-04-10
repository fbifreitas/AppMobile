import { NextRequest, NextResponse } from "next/server";
import { buildAuthenticatedHeaders, readAuthSession, unauthorizedJson } from "../../../lib/auth_session";
import { callBackendConfigApi } from "../../../lib/config_backend_client";
import {
  actorRoleFromSession,
  canAccessConfigTenant,
  canPerformConfigAction,
  getPolicyErrorMessage
} from "../../../lib/config_policy";

export function GET(request: NextRequest) {
  const session = readAuthSession(request);
  if (!session) {
    return unauthorizedJson();
  }

  const tenantId = request.nextUrl.searchParams.get("tenantId") ?? session.tenantId;
  const limit = Number(request.nextUrl.searchParams.get("limit") ?? "20");
  const actorRole = actorRoleFromSession(session);

  if (!canPerformConfigAction(actorRole, "read")) {
    return NextResponse.json({ error: getPolicyErrorMessage(actorRole, "read") }, { status: 403 });
  }

  if (!canAccessConfigTenant(session, tenantId)) {
    return NextResponse.json({ error: "Tenant da configuracao difere da sessao autenticada" }, { status: 403 });
  }

  const normalizedLimit = Number.isFinite(limit) ? Math.max(1, limit) : 20;
  const query = new URLSearchParams({ tenantId, actorRole });

  return callBackendConfigApi<{ items: unknown[]; count: number; generatedAt: string }>(
    "audit",
    {
      headers: buildAuthenticatedHeaders(session, "config-audit")
    },
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
