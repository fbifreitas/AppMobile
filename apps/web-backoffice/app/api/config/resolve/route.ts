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

  const input = {
    tenantId: request.nextUrl.searchParams.get("tenantId") ?? session.tenantId,
    unitId: request.nextUrl.searchParams.get("unitId") ?? undefined,
    roleId: request.nextUrl.searchParams.get("roleId") ?? undefined,
    userId: request.nextUrl.searchParams.get("userId") ?? undefined,
    deviceId: request.nextUrl.searchParams.get("deviceId") ?? undefined
  };
  const actorRole = actorRoleFromSession(session);

  if (!canPerformConfigAction(actorRole, "read")) {
    return NextResponse.json({ error: getPolicyErrorMessage(actorRole, "read") }, { status: 403 });
  }

  if (!canAccessConfigTenant(session, input.tenantId)) {
    return NextResponse.json({ error: "Tenant da configuracao difere da sessao autenticada" }, { status: 403 });
  }

  const query = new URLSearchParams({
    tenantId: input.tenantId,
    actorRole
  });

  if (input.unitId) {
    query.set("unitId", input.unitId);
  }

  if (input.roleId) {
    query.set("roleId", input.roleId);
  }

  if (input.userId) {
    query.set("userId", input.userId);
  }

  if (input.deviceId) {
    query.set("deviceId", input.deviceId);
  }

  return callBackendConfigApi<{ input: unknown; result: unknown }>("resolve", {
    headers: buildAuthenticatedHeaders(session, "config-resolve")
  }, query)
    .then(({ status, payload }) =>
      NextResponse.json(
        {
          ...payload,
          metadata: {
            model: "backend-persistent-v1",
            generatedAt: new Date().toISOString()
          }
        },
        { status }
      )
    )
    .catch(() =>
      NextResponse.json(
        { error: "Falha ao resolver configuracao no backend" },
        { status: 502 }
      )
    );
}
