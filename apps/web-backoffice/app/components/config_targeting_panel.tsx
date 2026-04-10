"use client";

import React from "react";
import { useEffect, useMemo, useState } from "react";
import type { ActorRole } from "../lib/config_policy";

type ResolveResponse = {
  input: {
    tenantId: string;
    unitId?: string;
    roleId?: string;
    userId?: string;
    deviceId?: string;
  };
  result: {
    effective: Record<string, unknown>;
    appliedPackages: Array<{
      id: string;
      scope: string;
      updatedAt: string;
      status?: "pending_approval" | "active" | "rolled_back";
      rollout?: {
        activation: "immediate" | "scheduled";
        startsAt?: string;
        endsAt?: string;
        batchUserIds?: string[];
      };
      selector?: Record<string, string>;
    }>;
  };
  metadata: {
    model: string;
    generatedAt: string;
  };
};

type PackagesResponse = {
  items: Array<{
    id: string;
    scope: string;
    status?: "pending_approval" | "active" | "rolled_back";
    updatedAt: string;
    rollout?: {
      activation: "immediate" | "scheduled";
      startsAt?: string;
      endsAt?: string;
      batchUserIds?: string[];
    };
  }>;
};

type AuditResponse = {
  items: Array<{
    id: string;
    packageId: string;
    actorId: string;
    scope: string;
    createdAt: string;
  }>;
};

type AuthMeResponse = {
  tenantId: string;
  membershipRole: string;
};

async function fetchPackages(tenantId: string, actorRole: ActorRole): Promise<PackagesResponse> {
  const response = await fetch(
    `/api/config/packages?tenantId=${encodeURIComponent(tenantId)}&actorRole=${encodeURIComponent(actorRole)}`,
    {
      cache: "no-store"
    }
  );

  if (!response.ok) {
    throw new Error(`Falha ao listar pacotes: ${response.status}`);
  }

  return (await response.json()) as PackagesResponse;
}

async function fetchAuditByRole(tenantId: string, actorRole: ActorRole): Promise<AuditResponse> {
  const response = await fetch(
    `/api/config/audit?tenantId=${encodeURIComponent(tenantId)}&limit=10&actorRole=${encodeURIComponent(actorRole)}`,
    {
      cache: "no-store"
    }
  );

  if (!response.ok) {
    throw new Error(`Falha na auditoria: ${response.status}`);
  }

  return (await response.json()) as AuditResponse;
}

async function fetchResolveByRole(query: URLSearchParams): Promise<ResolveResponse> {
  const response = await fetch(`/api/config/resolve?${query.toString()}`, {
    cache: "no-store"
  });

  if (!response.ok) {
    throw new Error(`Falha no resolve: ${response.status}`);
  }

  return (await response.json()) as ResolveResponse;
}

function toPretty(value: unknown): string {
  if (typeof value === "boolean") {
    return value ? "true" : "false";
  }

  if (value === undefined || value === null) {
    return "-";
  }

  return String(value);
}

export default function ConfigTargetingPanel() {
  const [tenantId, setTenantId] = useState("");
  const [roleId, setRoleId] = useState("vistoriador");
  const [userId, setUserId] = useState("user-42");
  const [deviceId, setDeviceId] = useState("device-x7");
  const [loading, setLoading] = useState(false);
  const [publishing, setPublishing] = useState(false);
  const [rollingBackId, setRollingBackId] = useState<string | null>(null);
  const [approvingId, setApprovingId] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [payload, setPayload] = useState<ResolveResponse | null>(null);
  const [audit, setAudit] = useState<AuditResponse["items"]>([]);
  const [packages, setPackages] = useState<PackagesResponse["items"]>([]);
  const [publishScope, setPublishScope] = useState<"tenant" | "role" | "user" | "device">("user");
  const [publishChannel, setPublishChannel] = useState<"stable" | "pilot" | "hotfix">("pilot");
  const [publishVoice, setPublishVoice] = useState(true);
  const [actorRole, setActorRole] = useState<ActorRole>("tenant_admin");
  const [publishActivation, setPublishActivation] = useState<"immediate" | "scheduled">("immediate");
  const [publishStartsAt, setPublishStartsAt] = useState("");
  const [publishEndsAt, setPublishEndsAt] = useState("");
  const [publishBatchUsers, setPublishBatchUsers] = useState("");
  const [publishSectionsJson, setPublishSectionsJson] = useState(
    '[\n  {\n    "sectionKey": "fachada",\n    "sectionLabel": "Fachada",\n    "mandatory": true,\n    "photoMin": 1,\n    "photoMax": 5,\n    "desiredItems": ["orientacao", "material"],\n    "tipoImovel": "Urbano",\n    "sortOrder": 1\n  }\n]'
  );

  useEffect(() => {
    let active = true;

    const run = async () => {
      try {
        const response = await fetch("/api/auth/me", { cache: "no-store" });
        if (!response.ok) {
          throw new Error(`Falha ao carregar sessao: ${response.status}`);
        }
        const session = (await response.json()) as AuthMeResponse;
        if (active) {
          setTenantId(session.tenantId);
          setActorRole(
            session.membershipRole === "TENANT_ADMIN" || session.membershipRole === "PLATFORM_ADMIN"
              ? "tenant_admin"
              : session.membershipRole === "AUDITOR"
                ? "viewer"
                : "operator"
          );
        }
      } catch (err) {
        if (active) {
          setError(err instanceof Error ? err.message : "Erro ao carregar sessao autenticada");
        }
      }
    };

    run();

    return () => {
      active = false;
    };
  }, []);

  const query = useMemo(() => {
    const params = new URLSearchParams();
    params.set("tenantId", tenantId);
    params.set("actorRole", actorRole);

    if (roleId.trim()) {
      params.set("roleId", roleId.trim());
    }

    if (userId.trim()) {
      params.set("userId", userId.trim());
    }

    if (deviceId.trim()) {
      params.set("deviceId", deviceId.trim());
    }

    return params;
  }, [tenantId, roleId, userId, deviceId, actorRole]);

  useEffect(() => {
    let active = true;

    const run = async () => {
      if (!tenantId.trim()) {
        return;
      }

      setLoading(true);
      setError(null);

      try {
        const resolved = await fetchResolveByRole(query);
        const auditResult = await fetchAuditByRole(tenantId, actorRole);
        const packagesResult = await fetchPackages(tenantId, actorRole);

        if (!active) {
          return;
        }

        setPayload(resolved);
        setAudit(auditResult.items);
        setPackages(packagesResult.items);
      } catch (err) {
        if (!active) {
          return;
        }

        setError(err instanceof Error ? err.message : "Erro nao identificado");
      } finally {
        if (active) {
          setLoading(false);
        }
      }
    };

    run();

    return () => {
      active = false;
    };
  }, [query, tenantId, actorRole]);

  const publishPackage = async () => {
    if (!tenantId.trim()) {
      setError("Tenant autenticado ainda nao carregado.");
      return;
    }

    setPublishing(true);
    setError(null);

    const selector: Record<string, string> = {};

    if (publishScope === "role" && roleId.trim()) {
      selector.roleId = roleId.trim();
    }

    if (publishScope === "user" && userId.trim()) {
      selector.userId = userId.trim();
    }

    if (publishScope === "device" && deviceId.trim()) {
      selector.deviceId = deviceId.trim();
    }

    let parsedSections: unknown;
    try {
      parsedSections = JSON.parse(publishSectionsJson);
      if (!Array.isArray(parsedSections)) {
        throw new Error("JSON de secoes deve ser um array.");
      }
    } catch (parseError) {
      setPublishing(false);
      setError(
        parseError instanceof Error
          ? `JSON de secoes invalido: ${parseError.message}`
          : "JSON de secoes invalido."
      );
      return;
    }

    const response = await fetch("/api/config/packages", {
      method: "POST",
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        actorId: "operator-web",
        actorRole,
        scope: publishScope,
        tenantId,
        selector,
        rollout: {
          activation: publishActivation,
          startsAt: publishStartsAt ? new Date(publishStartsAt).toISOString() : undefined,
          endsAt: publishEndsAt ? new Date(publishEndsAt).toISOString() : undefined,
          batchUserIds: publishBatchUsers
            .split(",")
            .map((value) => value.trim())
            .filter(Boolean)
        },
        rules: {
          appUpdateChannel: publishChannel,
          enableVoiceCommands: publishVoice,
          checkinSections: parsedSections
        }
      })
    });

    if (!response.ok) {
      setPublishing(false);
      setError(`Falha ao publicar pacote: HTTP ${response.status}`);
      return;
    }

    const [resolved, auditResult, packagesResult] = await Promise.all([
      fetchResolveByRole(query),
      fetchAuditByRole(tenantId, actorRole),
      fetchPackages(tenantId, actorRole)
    ]);
    setPayload(resolved);
    setAudit(auditResult.items);
    setPackages(packagesResult.items);
    setPublishing(false);
  };

  const rollbackPackage = async (packageId: string) => {
    if (!tenantId.trim()) {
      setError("Tenant autenticado ainda nao carregado.");
      return;
    }

    setRollingBackId(packageId);
    setError(null);

    const response = await fetch("/api/config/packages/rollback", {
      method: "POST",
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        packageId,
        tenantId,
        actorId: "operator-web",
        actorRole
      })
    });

    if (!response.ok) {
      setRollingBackId(null);
      setError(`Falha ao reverter pacote: HTTP ${response.status}`);
      return;
    }

    const [resolved, auditResult, packagesResult] = await Promise.all([
      fetchResolveByRole(query),
      fetchAuditByRole(tenantId, actorRole),
      fetchPackages(tenantId, actorRole)
    ]);
    setPayload(resolved);
    setAudit(auditResult.items);
    setPackages(packagesResult.items);
    setRollingBackId(null);
  };

  const approvePackage = async (packageId: string) => {
    if (!tenantId.trim()) {
      setError("Tenant autenticado ainda nao carregado.");
      return;
    }

    setApprovingId(packageId);
    setError(null);

    const response = await fetch("/api/config/packages/approve", {
      method: "POST",
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        packageId,
        tenantId,
        actorId: "approver-web",
        actorRole
      })
    });

    if (!response.ok) {
      setApprovingId(null);
      setError(`Falha ao aprovar pacote: HTTP ${response.status}`);
      return;
    }

    const [resolved, auditResult, packagesResult] = await Promise.all([
      fetchResolveByRole(query),
      fetchAuditByRole(tenantId, actorRole),
      fetchPackages(tenantId, actorRole)
    ]);
    setPayload(resolved);
    setAudit(auditResult.items);
    setPackages(packagesResult.items);
    setApprovingId(null);
  };

  return (
    <section className="targeting-panel" aria-live="polite">
      <div className="targeting-header">
        <h2>Resolucao de configuracao multi-escopo</h2>
        <p>Simulacao de precedencia: global -&gt; tenant -&gt; role -&gt; user -&gt; device.</p>
      </div>

      <div className="targeting-filters">
        <label>
          Perfil operacional
          <select value={actorRole} onChange={(event) => setActorRole(event.target.value as ActorRole)}>
            <option value="viewer">viewer</option>
            <option value="operator">operator</option>
            <option value="tenant_admin">tenant_admin</option>
            <option value="support">support</option>
          </select>
        </label>
        <label>
          Tenant
          <input value={tenantId} onChange={(event) => setTenantId(event.target.value)} />
        </label>
        <label>
          Role
          <input value={roleId} onChange={(event) => setRoleId(event.target.value)} />
        </label>
        <label>
          Usuario
          <input value={userId} onChange={(event) => setUserId(event.target.value)} />
        </label>
        <label>
          Dispositivo
          <input value={deviceId} onChange={(event) => setDeviceId(event.target.value)} />
        </label>
      </div>

      <div className="publish-box">
        <h3>Publicar pacote de configuracao</h3>
        <div className="publish-grid">
          <label>
            Escopo
            <select value={publishScope} onChange={(event) => setPublishScope(event.target.value as "tenant" | "role" | "user" | "device")}>
              <option value="tenant">tenant</option>
              <option value="role">role</option>
              <option value="user">user</option>
              <option value="device">device</option>
            </select>
          </label>
          <label>
            Canal de update
            <select
              value={publishChannel}
              onChange={(event) =>
                setPublishChannel(event.target.value as "stable" | "pilot" | "hotfix")
              }
            >
              <option value="stable">stable</option>
              <option value="pilot">pilot</option>
              <option value="hotfix">hotfix</option>
            </select>
          </label>
          <label>
            Ativacao
            <select
              value={publishActivation}
              onChange={(event) =>
                setPublishActivation(event.target.value as "immediate" | "scheduled")
              }
            >
              <option value="immediate">immediate</option>
              <option value="scheduled">scheduled</option>
            </select>
          </label>
          <label>
            Inicio (opcional)
            <input
              type="datetime-local"
              value={publishStartsAt}
              onChange={(event) => setPublishStartsAt(event.target.value)}
            />
          </label>
          <label>
            Fim (opcional)
            <input
              type="datetime-local"
              value={publishEndsAt}
              onChange={(event) => setPublishEndsAt(event.target.value)}
            />
          </label>
          <label>
            Lote de usuarios (csv)
            <input
              placeholder="user-42,user-77"
              value={publishBatchUsers}
              onChange={(event) => setPublishBatchUsers(event.target.value)}
            />
          </label>
          <label className="check-label">
            <input
              type="checkbox"
              checked={publishVoice}
              onChange={(event) => setPublishVoice(event.target.checked)}
            />
            Habilitar comandos de voz
          </label>
        </div>
        <label>
          JSON de secoes check-in (BOW-130)
          <textarea
            value={publishSectionsJson}
            onChange={(event) => setPublishSectionsJson(event.target.value)}
            rows={10}
          />
        </label>
        <button type="button" onClick={publishPackage} disabled={publishing}>
          {publishing ? "Publicando..." : "Publicar para aprovacao"}
        </button>
      </div>

      <div className="targeting-trace">
        <h3>Catalogo de pacotes</h3>
        <ul>
          {packages.map((pkg) => (
            <li key={pkg.id}>
              <strong>{pkg.id}</strong> ({pkg.scope})
              <span className={`pkg-status state-${pkg.status ?? "active"}`}>
                {pkg.status ?? "active"}
              </span>
              {pkg.status === "pending_approval" && (
                <button
                  type="button"
                  className="inline-action inline-approve"
                  onClick={() => approvePackage(pkg.id)}
                  disabled={approvingId === pkg.id}
                >
                  {approvingId === pkg.id ? "Aprovando..." : "Aprovar"}
                </button>
              )}
              {pkg.status !== "rolled_back" && (
                <button
                  type="button"
                  className="inline-action"
                  onClick={() => rollbackPackage(pkg.id)}
                  disabled={rollingBackId === pkg.id}
                >
                  {rollingBackId === pkg.id ? "Revertendo..." : "Rollback"}
                </button>
              )}
            </li>
          ))}
        </ul>
      </div>

      {loading && <p className="targeting-note">Calculando configuracao efetiva...</p>}
      {error && <p className="targeting-error">{error}</p>}

      {payload && (
        <>
          <div className="targeting-grid">
            {Object.entries(payload.result.effective).map(([key, value]) => (
              <article className="targeting-item" key={key}>
                <h3>{key}</h3>
                <p>{toPretty(value)}</p>
              </article>
            ))}
          </div>

          <div className="targeting-trace">
            <h3>Pacotes aplicados</h3>
            <ul>
              {payload.result.appliedPackages.map((pkg) => (
                <li key={pkg.id}>
                  <strong>{pkg.id}</strong> ({pkg.scope})
                  <span className={`pkg-status state-${pkg.status ?? "active"}`}>
                    {pkg.status ?? "active"}
                  </span>
                  {pkg.rollout && (
                    <span className="pkg-rollout">
                      rollout: {pkg.rollout.activation}
                    </span>
                  )}
                </li>
              ))}
            </ul>
          </div>

          <div className="targeting-trace">
            <h3>Auditoria recente</h3>
            <ul>
              {audit.map((entry) => (
                <li key={entry.id}>
                  <strong>{entry.packageId}</strong> | {entry.scope} | {entry.actorId}
                </li>
              ))}
            </ul>
          </div>
        </>
      )}
    </section>
  );
}
