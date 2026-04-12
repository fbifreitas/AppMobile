import { randomUUID } from "node:crypto";

const DEFAULT_BACKEND_CONFIG_BASE_URL = "http://localhost:8080/api/backoffice/config";

function buildCorrelationId(): string {
  return `cfg-${randomUUID()}`;
}

function getBackendBaseUrl(): string {
  const configured = process.env.BACKOFFICE_CONFIG_API_BASE_URL?.trim();
  if (configured && configured.length > 0) {
    return configured;
  }

  const backendBase = process.env.BACKEND_API_URL?.trim();
  if (backendBase && backendBase.length > 0) {
    return `${backendBase.replace(/\/$/, "")}/api/backoffice/config`;
  }

  return DEFAULT_BACKEND_CONFIG_BASE_URL;
}

export function buildBackendConfigUrl(path: string, query?: URLSearchParams): string {
  const normalizedPath = path.startsWith("/") ? path.slice(1) : path;
  const url = new URL(normalizedPath, `${getBackendBaseUrl().replace(/\/$/, "")}/`);

  if (query) {
    url.search = query.toString();
  }

  return url.toString();
}

export async function callBackendConfigApi<T>(
  path: string,
  init?: RequestInit,
  query?: URLSearchParams
): Promise<{ status: number; payload: T }> {
  const headers = new Headers(init?.headers ?? {});

  if (!headers.has("Content-Type")) {
    headers.set("Content-Type", "application/json");
  }

  if (!headers.has("X-Correlation-Id")) {
    headers.set("X-Correlation-Id", buildCorrelationId());
  }

  const response = await fetch(buildBackendConfigUrl(path, query), {
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
