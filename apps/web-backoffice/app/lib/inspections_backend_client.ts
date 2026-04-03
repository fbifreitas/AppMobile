import { randomUUID } from "node:crypto";

const DEFAULT_BACKEND_INSPECTIONS_BASE_URL = "http://localhost/api/backoffice/inspections";

function buildCorrelationId(): string {
  return `insp-${randomUUID()}`;
}

function getBackendBaseUrl(): string {
  const configured = process.env.BACKOFFICE_INSPECTIONS_API_BASE_URL?.trim();
  return configured && configured.length > 0 ? configured : DEFAULT_BACKEND_INSPECTIONS_BASE_URL;
}

export function buildBackendInspectionsUrl(path: string, query?: URLSearchParams): string {
  const normalizedPath = path.startsWith("/") ? path.slice(1) : path;
  const url = new URL(normalizedPath, `${getBackendBaseUrl().replace(/\/$/, "")}/`);

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

  const payload = (await response.json()) as T;

  return {
    status: response.status,
    payload
  };
}
