import { NextRequest, NextResponse } from "next/server";
import { buildAuthenticatedHeaders, readAuthSession, unauthorizedJson } from "../../../../lib/auth_session";
import { callBackendConfigApi } from "../../../../lib/config_backend_client";
import {
  actorRoleFromSession,
  canAccessConfigTenant,
  canPerformConfigAction,
  getPolicyErrorMessage,
  type ActorRole
} from "../../../../lib/config_policy";

type RollbackPayload = {
  packageId: string;
  tenantId: string;
  actorId?: string;
  actorRole?: ActorRole;
};

export async function POST(request: NextRequest) {
  const session = readAuthSession(request);
  if (!session) {
    return unauthorizedJson();
  }

  const body = (await request.json()) as RollbackPayload;

  if (!body?.packageId || !body?.tenantId) {
    return NextResponse.json({ error: "Campos obrigatorios ausentes: packageId e tenantId" }, { status: 400 });
  }

  if (!canAccessConfigTenant(session, body.tenantId)) {
    return NextResponse.json({ error: "Tenant da configuracao difere da sessao autenticada" }, { status: 403 });
  }

  const actorRole = actorRoleFromSession(session);

  if (!canPerformConfigAction(actorRole, "rollback")) {
    return NextResponse.json(
      { error: getPolicyErrorMessage(actorRole, "rollback") },
      { status: 403 }
    );
  }

  return callBackendConfigApi("packages/rollback", {
    method: "POST",
    headers: buildAuthenticatedHeaders(session, "config-rollback"),
    body: JSON.stringify({
      packageId: body.packageId,
      tenantId: body.tenantId,
      actorId: String(session.userId),
      actorRole
    })
  })
    .then(({ status, payload }) => NextResponse.json(payload, { status }))
    .catch(() =>
      NextResponse.json(
        { error: "Falha ao reverter pacote no backend" },
        { status: 502 }
      )
    );
}
