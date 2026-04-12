import { randomUUID } from "node:crypto";

const DEFAULT_BACKEND_OPERATIONS_BASE_URL = "http://localhost:8080/api";
const ROOT_OPERATION_RESOURCES = ["cases", "jobs"];

type RequestContext = {
  tenantId?: string;
  actorId?: string;
  correlationPrefix?: string;
};

function buildCorrelationId(prefix = "ops"): string {
  return `${prefix}-${randomUUID()}`;
}

function getBackendBaseUrl(): string {
  const configured = process.env.BACKOFFICE_OPERATIONS_API_BASE_URL?.trim();
  const fallback = process.env.BACKEND_API_URL?.trim();
  return configured && configured.length > 0
    ? configured
    : fallback && fallback.length > 0
      ? `${fallback.replace(/\/$/, "")}/api`
      : DEFAULT_BACKEND_OPERATIONS_BASE_URL;
}

function usesRootOperationsBase(path: string): boolean {
  const normalizedPath = path.startsWith("/") ? path.slice(1) : path;
  return ROOT_OPERATION_RESOURCES.some(
    (resource) =>
      normalizedPath === resource || normalizedPath.startsWith(`${resource}/`)
  );
}

export function buildBackendOperationsUrl(path: string, query?: URLSearchParams): string {
  const normalizedPath = path.startsWith("/") ? path.slice(1) : path;
  const configuredApiBase = getBackendBaseUrl().replace(/\/$/, "");
  const rootBase = configuredApiBase.endsWith("/api")
    ? configuredApiBase.slice(0, -4)
    : configuredApiBase;
  const selectedBase = usesRootOperationsBase(normalizedPath)
    ? `${rootBase}/`
    : `${configuredApiBase}/`;
  const url = new URL(normalizedPath, selectedBase);

  if (query) {
    url.search = query.toString();
  }

  return url.toString();
}

export async function callBackendOperationsApi<T>(
  path: string,
  init?: RequestInit,
  query?: URLSearchParams,
  context?: RequestContext
): Promise<{ status: number; payload: T }> {
  const headers = new Headers(init?.headers ?? {});

  if (!headers.has("Content-Type")) {
    headers.set("Content-Type", "application/json");
  }

  if (!headers.has("X-Tenant-Id")) {
    headers.set("X-Tenant-Id", context?.tenantId?.trim() || "tenant-default");
  }

  if (!headers.has("X-Actor-Id")) {
    headers.set("X-Actor-Id", context?.actorId?.trim() || "backoffice-operator");
  }

  if (!headers.has("X-Correlation-Id")) {
    headers.set("X-Correlation-Id", buildCorrelationId(context?.correlationPrefix));
  }

  const response = await fetch(buildBackendOperationsUrl(path, query), {
    cache: "no-store",
    ...init,
    headers
  });

  const payload = (await response.json()) as T;

  return {
    status: response.status,
    payload
  };
}
