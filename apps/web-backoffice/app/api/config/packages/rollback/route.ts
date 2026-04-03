import { NextRequest, NextResponse } from "next/server";
import { callBackendConfigApi } from "../../../../lib/config_backend_client";
import {
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
  const body = (await request.json()) as RollbackPayload;

  if (!body?.packageId || !body?.tenantId) {
    return NextResponse.json({ error: "Campos obrigatorios ausentes: packageId e tenantId" }, { status: 400 });
  }

  const actorRole = body.actorRole ?? "tenant_admin";

  if (!canPerformConfigAction(actorRole, "rollback")) {
    return NextResponse.json(
      { error: getPolicyErrorMessage(actorRole, "rollback") },
      { status: 403 }
    );
  }

  return callBackendConfigApi("packages/rollback", {
    method: "POST",
    body: JSON.stringify({
      packageId: body.packageId,
      tenantId: body.tenantId,
      actorId: body.actorId ?? "operator-web",
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
