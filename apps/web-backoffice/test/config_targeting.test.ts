import assert from "node:assert/strict";
import test from "node:test";

import {
  resolveEffectiveConfig,
  type ConfigPackage,
  type ResolveInput
} from "../app/lib/config_targeting";

function makeInput(overrides: Partial<ResolveInput> = {}): ResolveInput {
  return {
    tenantId: "tenant-alpha",
    roleId: "vistoriador",
    userId: "user-42",
    deviceId: "device-x7",
    ...overrides
  };
}

test("resolveEffectiveConfig aplica precedencia do mais generico ao mais especifico", () => {
  const packages: ConfigPackage[] = [
    {
      id: "global",
      scope: "global",
      tenantId: "tenant-alpha",
      updatedAt: "2026-04-02T10:00:00.000Z",
      status: "active",
      rules: { appUpdateChannel: "stable", enableVoiceCommands: true }
    },
    {
      id: "user",
      scope: "user",
      tenantId: "tenant-alpha",
      selector: { userId: "user-42" },
      updatedAt: "2026-04-02T10:10:00.000Z",
      status: "active",
      rules: { appUpdateChannel: "hotfix" }
    },
    {
      id: "device",
      scope: "device",
      tenantId: "tenant-alpha",
      selector: { deviceId: "device-x7" },
      updatedAt: "2026-04-02T10:20:00.000Z",
      status: "active",
      rules: { theme: "dark" }
    }
  ];

  const result = resolveEffectiveConfig(packages, makeInput());

  assert.deepEqual(result.effective, {
    appUpdateChannel: "hotfix",
    enableVoiceCommands: true,
    theme: "dark"
  });
  assert.deepEqual(
    result.appliedPackages.map((entry) => entry.id),
    ["global", "user", "device"]
  );
});

test("resolveEffectiveConfig ignora pacote pendente ou rolled_back", () => {
  const packages: ConfigPackage[] = [
    {
      id: "pending",
      scope: "tenant",
      tenantId: "tenant-alpha",
      updatedAt: "2026-04-02T10:00:00.000Z",
      status: "pending_approval",
      rules: { cameraMaxPhotos: 9 }
    },
    {
      id: "rolled",
      scope: "role",
      tenantId: "tenant-alpha",
      selector: { roleId: "vistoriador" },
      updatedAt: "2026-04-02T10:02:00.000Z",
      status: "rolled_back",
      rules: { cameraMinPhotos: 4 }
    },
    {
      id: "active",
      scope: "global",
      tenantId: "tenant-alpha",
      updatedAt: "2026-04-02T10:03:00.000Z",
      status: "active",
      rules: { cameraMinPhotos: 1 }
    }
  ];

  const result = resolveEffectiveConfig(packages, makeInput());

  assert.deepEqual(result.effective, { cameraMinPhotos: 1 });
  assert.deepEqual(
    result.appliedPackages.map((entry) => entry.id),
    ["active"]
  );
});

test("resolveEffectiveConfig respeita rollout agendado fora da janela", () => {
  const packages: ConfigPackage[] = [
    {
      id: "scheduled-future",
      scope: "user",
      tenantId: "tenant-alpha",
      selector: { userId: "user-42" },
      updatedAt: "2026-04-02T10:00:00.000Z",
      status: "active",
      rollout: {
        activation: "scheduled",
        startsAt: "2999-01-01T00:00:00.000Z",
        endsAt: "2999-01-02T00:00:00.000Z"
      },
      rules: { appUpdateChannel: "pilot" }
    }
  ];

  const result = resolveEffectiveConfig(packages, makeInput());

  assert.deepEqual(result.effective, {});
  assert.equal(result.appliedPackages.length, 0);
});

test("resolveEffectiveConfig respeita lote de usuarios no rollout", () => {
  const packages: ConfigPackage[] = [
    {
      id: "batch-users",
      scope: "tenant",
      tenantId: "tenant-alpha",
      updatedAt: "2026-04-02T10:00:00.000Z",
      status: "active",
      rollout: {
        activation: "immediate",
        batchUserIds: ["user-42", "user-77"]
      },
      rules: { enableVoiceCommands: false }
    }
  ];

  const included = resolveEffectiveConfig(packages, makeInput({ userId: "user-42" }));
  const excluded = resolveEffectiveConfig(packages, makeInput({ userId: "user-99" }));

  assert.deepEqual(included.effective, { enableVoiceCommands: false });
  assert.deepEqual(excluded.effective, {});
});