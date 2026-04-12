import { randomUUID } from "node:crypto";

const DEFAULT_BACKEND_INSPECTIONS_BASE_URL = "http://localhost:8080/api/backoffice/inspections";

function buildCorrelationId(): string {
  return `insp-${randomUUID()}`;
}

function getBackendBaseUrl(): string {
  const configured = process.env.BACKOFFICE_INSPECTIONS_API_BASE_URL?.trim();
  if (configured && configured.length > 0) {
    return configured;
  }

  const backendBase = process.env.BACKEND_API_URL?.trim();
  if (backendBase && backendBase.length > 0) {
    return `${backendBase.replace(/\/$/, "")}/api/backoffice/inspections`;
  }

  return DEFAULT_BACKEND_INSPECTIONS_BASE_URL;
}

export function buildBackendInspectionsUrl(path: string, query?: URLSearchParams): string {
  const normalizedPath = path.startsWith("/") ? path.slice(1) : path;
  const baseUrl = getBackendBaseUrl().replace(/\/$/, "");
  const url = normalizedPath.length > 0
    ? new URL(normalizedPath, `${baseUrl}/`)
    : new URL(baseUrl);

  if (query) {
    url.search = query.toString();
  }

  return url.toString();
}

export async function callBackendInspectionsApi<T>(
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

  const response = await fetch(buildBackendInspectionsUrl(path, query), {
    cache: "no-store",
    ...init,
    headers
  });

  const responseText = await response.text();
  const payload = (responseText.length > 0 ? JSON.parse(responseText) : null) as T;

  return {
    status: response.status,
    payload
  };
}
