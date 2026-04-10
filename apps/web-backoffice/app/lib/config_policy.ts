import type { AuthSession } from "./auth_session";

export type ActorRole = "viewer" | "operator" | "tenant_admin" | "support";
export type ConfigAction = "publish" | "approve" | "rollback" | "read";

const permissions: Record<ActorRole, ConfigAction[]> = {
  viewer: ["read"],
  operator: ["read", "publish"],
  tenant_admin: ["read", "publish", "approve", "rollback"],
  support: ["read", "rollback"]
};

export function canPerformConfigAction(role: ActorRole, action: ConfigAction): boolean {
  return permissions[role].includes(action);
}

export function getPolicyErrorMessage(role: ActorRole, action: ConfigAction): string {
  return `Perfil ${role} nao possui permissao para ${action} pacote de configuracao.`;
}

export function actorRoleFromSession(session: AuthSession): ActorRole {
  if (session.membershipRole === "TENANT_ADMIN" || session.membershipRole === "PLATFORM_ADMIN") {
    return "tenant_admin";
  }

  if (session.membershipRole === "AUDITOR") {
    return "viewer";
  }

  return "operator";
}

export function canAccessConfigTenant(session: AuthSession, tenantId: string): boolean {
  return session.tenantId === tenantId;
}
