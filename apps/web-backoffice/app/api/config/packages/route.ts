import { NextRequest, NextResponse } from "next/server";
import type { ConfigRules, RolloutPolicy, TargetScope } from "../../../lib/config_targeting";
import { callBackendConfigApi } from "../../../lib/config_backend_client";
import {
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
  const tenantId = request.nextUrl.searchParams.get("tenantId") ?? undefined;
  const actorRole = (request.nextUrl.searchParams.get("actorRole") ?? "tenant_admin") as ActorRole;

  if (!canPerformConfigAction(actorRole, "read")) {
    return NextResponse.json({ error: getPolicyErrorMessage(actorRole, "read") }, { status: 403 });
  }

  if (!tenantId) {
    return NextResponse.json({ error: "Campo obrigatorio ausente: tenantId" }, { status: 400 });
  }

  const query = new URLSearchParams({ tenantId, actorRole });

  return callBackendConfigApi("packages", undefined, query)
    .then(({ status, payload }) => NextResponse.json(payload, { status }))
    .catch(() =>
      NextResponse.json(
        { error: "Falha ao consultar pacotes no backend" },
        { status: 502 }
      )
    );
}

export async function POST(request: NextRequest) {
  const body = (await request.json()) as PublishPayload;

  if (!body?.tenantId || !body?.scope || !body?.rules) {
    return NextResponse.json(
      {
        error: "Campos obrigatorios ausentes: tenantId, scope e rules"
      },
      { status: 400 }
    );
  }

  const actorRole = body.actorRole ?? "operator";

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
      body: JSON.stringify({
        actorId: body.actorId ?? "operator-web",
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
