import { NextRequest, NextResponse } from "next/server";
import { callBackendConfigApi } from "../../../../lib/config_backend_client";
import {
  canPerformConfigAction,
  getPolicyErrorMessage,
  type ActorRole
} from "../../../../lib/config_policy";

type ApprovePayload = {
  packageId: string;
  tenantId: string;
  actorId?: string;
  actorRole?: ActorRole;
};

export async function POST(request: NextRequest) {
  const body = (await request.json()) as ApprovePayload;

  if (!body?.packageId || !body?.tenantId) {
    return NextResponse.json({ error: "Campos obrigatorios ausentes: packageId e tenantId" }, { status: 400 });
  }

  const actorRole = body.actorRole ?? "tenant_admin";

  if (!canPerformConfigAction(actorRole, "approve")) {
    return NextResponse.json(
      { error: getPolicyErrorMessage(actorRole, "approve") },
      { status: 403 }
    );
  }

  return callBackendConfigApi("packages/approve", {
    method: "POST",
    body: JSON.stringify({
      packageId: body.packageId,
      tenantId: body.tenantId,
      actorId: body.actorId ?? "approver-web",
      actorRole
    })
  })
    .then(({ status, payload }) => NextResponse.json(payload, { status }))
    .catch(() =>
      NextResponse.json(
        { error: "Falha ao aprovar pacote no backend" },
        { status: 502 }
      )
    );
}
