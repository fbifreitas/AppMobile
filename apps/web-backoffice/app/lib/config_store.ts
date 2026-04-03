import {
  mockConfigPackages,
  type ConfigPackage,
  type ConfigRules,
  type RolloutPolicy,
  type TargetScope,
  type TargetSelector
} from "./config_targeting";
import type { ActorRole } from "./config_policy";

export type ConfigAuditEntry = {
  id: string;
  packageId: string;
  actorId: string;
  actorRole?: ActorRole;
  action: "publish" | "approve" | "rollback";
  tenantId: string;
  scope: TargetScope;
  selector?: TargetSelector;
  changedRules: ConfigRules;
  createdAt: string;
};

type PublishInput = {
  actorId?: string;
  actorRole?: ActorRole;
  scope: TargetScope;
  tenantId: string;
  selector?: TargetSelector;
  rollout?: RolloutPolicy;
  activateImmediately?: boolean;
  rules: ConfigRules;
};

const packageStore: ConfigPackage[] = [...mockConfigPackages];
const auditStore: ConfigAuditEntry[] = [];

function nowIso(): string {
  return new Date().toISOString();
}

function makePackageId(scope: TargetScope): string {
  return `cfg-${scope}-${Date.now()}`;
}

function makeAuditId(): string {
  return `audit-${Date.now()}-${Math.round(Math.random() * 1000)}`;
}

export function listPackages(tenantId?: string): ConfigPackage[] {
  const all = tenantId ? packageStore.filter((pkg) => pkg.tenantId === tenantId) : [...packageStore];

  return all.sort((a, b) => Date.parse(a.updatedAt) - Date.parse(b.updatedAt));
}

export function publishPackage(input: PublishInput): { created: ConfigPackage; audit: ConfigAuditEntry } {
  const status = input.activateImmediately ? "active" : "pending_approval";

  const created: ConfigPackage = {
    id: makePackageId(input.scope),
    scope: input.scope,
    tenantId: input.tenantId,
    selector: input.selector,
    updatedAt: nowIso(),
    status,
    rollout: input.rollout ?? { activation: "immediate" },
    rules: input.rules
  };

  const audit: ConfigAuditEntry = {
    id: makeAuditId(),
    packageId: created.id,
    actorId: input.actorId ?? "backoffice-operator",
    actorRole: input.actorRole,
    action: "publish",
    tenantId: input.tenantId,
    scope: input.scope,
    selector: input.selector,
    changedRules: input.rules,
    createdAt: nowIso()
  };

  packageStore.push(created);
  auditStore.push(audit);

  return { created, audit };
}

export function listAudit(tenantId?: string, limit = 20): ConfigAuditEntry[] {
  const scoped = tenantId ? auditStore.filter((entry) => entry.tenantId === tenantId) : auditStore;

  return [...scoped].sort((a, b) => Date.parse(b.createdAt) - Date.parse(a.createdAt)).slice(0, limit);
}

export function rollbackPackage(
  packageId: string,
  actorId = "backoffice-operator",
  actorRole?: ActorRole
): { updated: ConfigPackage; audit: ConfigAuditEntry } | null {
  const pkg = packageStore.find((entry) => entry.id === packageId);

  if (!pkg) {
    return null;
  }

  pkg.status = "rolled_back";
  pkg.updatedAt = nowIso();

  const audit: ConfigAuditEntry = {
    id: makeAuditId(),
    packageId: pkg.id,
    actorId,
    actorRole,
    action: "rollback",
    tenantId: pkg.tenantId,
    scope: pkg.scope,
    selector: pkg.selector,
    changedRules: pkg.rules,
    createdAt: nowIso()
  };

  auditStore.push(audit);

  return {
    updated: pkg,
    audit
  };
}

export function approvePackage(
  packageId: string,
  actorId = "backoffice-approver",
  actorRole?: ActorRole
): { updated: ConfigPackage; audit: ConfigAuditEntry } | null {
  const pkg = packageStore.find((entry) => entry.id === packageId);

  if (!pkg) {
    return null;
  }

  if (pkg.status === "rolled_back") {
    return null;
  }

  pkg.status = "active";
  pkg.updatedAt = nowIso();

  const audit: ConfigAuditEntry = {
    id: makeAuditId(),
    packageId: pkg.id,
    actorId,
    actorRole,
    action: "approve",
    tenantId: pkg.tenantId,
    scope: pkg.scope,
    selector: pkg.selector,
    changedRules: pkg.rules,
    createdAt: nowIso()
  };

  auditStore.push(audit);

  return {
    updated: pkg,
    audit
  };
}
