import { NextRequest, NextResponse } from "next/server";
import type { ConfigRules, RolloutPolicy, TargetScope } from "../../../lib/config_targeting";
import { buildAuthenticatedHeaders, readAuthSession, unauthorizedJson } from "../../../lib/auth_session";
import { callBackendConfigApi } from "../../../lib/config_backend_client";
import {
  actorRoleFromSession,
  canAccessConfigTenant,
  canPerformConfigAction,
  getPolicyErrorMessage,
  type ActorRole
} from "../../../lib/config_policy";

type PublishPayload = {
  actorId?: string;
  actorRole?: ActorRole;
  scope: TargetScope;
  tenantId: string;
  selector?: {
    unitId?: string;
    roleId?: string;
    userId?: string;
    deviceId?: string;
  };
  rollout?: RolloutPolicy;
  activateImmediately?: boolean;
  rules: ConfigRules;
};

export function GET(request: NextRequest) {
  const session = readAuthSession(request);
  if (!session) {
    return unauthorizedJson();
  }

  const tenantId = request.nextUrl.searchParams.get("tenantId") ?? session.tenantId;
  const actorRole = actorRoleFromSession(session);

  if (!canPerformConfigAction(actorRole, "read")) {
    return NextResponse.json({ error: getPolicyErrorMessage(actorRole, "read") }, { status: 403 });
  }

  if (!canAccessConfigTenant(session, tenantId)) {
    return NextResponse.json({ error: "Tenant da configuracao difere da sessao autenticada" }, { status: 403 });
  }

  const query = new URLSearchParams({ tenantId, actorRole });

  return callBackendConfigApi("packages", {
    headers: buildAuthenticatedHeaders(session, "config-packages")
  }, query)
    .then(({ status, payload }) => NextResponse.json(payload, { status }))
    .catch(() =>
      NextResponse.json(
        { error: "Falha ao consultar pacotes no backend" },
        { status: 502 }
      )
    );
}

export async function POST(request: NextRequest) {
  const session = readAuthSession(request);
  if (!session) {
    return unauthorizedJson();
  }

  const body = (await request.json()) as PublishPayload;

  if (!body?.tenantId || !body?.scope || !body?.rules) {
    return NextResponse.json(
      {
        error: "Campos obrigatorios ausentes: tenantId, scope e rules"
      },
      { status: 400 }
    );
  }

  if (!canAccessConfigTenant(session, body.tenantId)) {
    return NextResponse.json({ error: "Tenant da configuracao difere da sessao autenticada" }, { status: 403 });
  }

  const actorRole = actorRoleFromSession(session);

  if (!canPerformConfigAction(actorRole, "publish")) {
    return NextResponse.json(
      { error: getPolicyErrorMessage(actorRole, "publish") },
      { status: 403 }
    );
  }

  return callBackendConfigApi(
    "packages",
    {
      method: "POST",
      headers: buildAuthenticatedHeaders(session, "config-packages"),
      body: JSON.stringify({
        actorId: String(session.userId),
        actorRole,
        scope: body.scope,
        tenantId: body.tenantId,
        selector: body.selector,
        rollout: body.rollout,
        rules: body.rules
      })
    }
  )
    .then(({ status, payload }) => NextResponse.json(payload, { status }))
    .catch(() =>
      NextResponse.json(
        { error: "Falha ao publicar pacote no backend" },
        { status: 502 }
      )
    );
}
