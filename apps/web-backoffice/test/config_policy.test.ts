import assert from "node:assert/strict";
import test from "node:test";

import { canPerformConfigAction, getPolicyErrorMessage } from "../app/lib/config_policy";

test("operator pode ler e publicar mas nao pode aprovar", () => {
  assert.equal(canPerformConfigAction("operator", "read"), true);
  assert.equal(canPerformConfigAction("operator", "publish"), true);
  assert.equal(canPerformConfigAction("operator", "approve"), false);
});

test("tenant_admin possui fluxo completo de governanca", () => {
  assert.equal(canPerformConfigAction("tenant_admin", "read"), true);
  assert.equal(canPerformConfigAction("tenant_admin", "publish"), true);
  assert.equal(canPerformConfigAction("tenant_admin", "approve"), true);
  assert.equal(canPerformConfigAction("tenant_admin", "rollback"), true);
});

test("viewer nao pode publicar pacote", () => {
  assert.equal(canPerformConfigAction("viewer", "publish"), false);
  assert.equal(
    getPolicyErrorMessage("viewer", "publish"),
    "Perfil viewer nao possui permissao para publish pacote de configuracao."
  );
});