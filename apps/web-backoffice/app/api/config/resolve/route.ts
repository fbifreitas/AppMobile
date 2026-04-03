import { NextRequest, NextResponse } from "next/server";
import { callBackendConfigApi } from "../../../lib/config_backend_client";
import {
  canPerformConfigAction,
  getPolicyErrorMessage,
  type ActorRole
} from "../../../lib/config_policy";

export function GET(request: NextRequest) {
  const input = {
    tenantId: request.nextUrl.searchParams.get("tenantId") ?? "tenant-alpha",
    unitId: request.nextUrl.searchParams.get("unitId") ?? undefined,
    roleId: request.nextUrl.searchParams.get("roleId") ?? undefined,
    userId: request.nextUrl.searchParams.get("userId") ?? undefined,
    deviceId: request.nextUrl.searchParams.get("deviceId") ?? undefined
  };
  const actorRole = (request.nextUrl.searchParams.get("actorRole") ?? "tenant_admin") as ActorRole;

  if (!canPerformConfigAction(actorRole, "read")) {
    return NextResponse.json({ error: getPolicyErrorMessage(actorRole, "read") }, { status: 403 });
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

  return callBackendConfigApi<{ input: unknown; result: unknown }>("resolve", undefined, query)
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
