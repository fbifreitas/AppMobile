import { NextRequest, NextResponse } from "next/server";

export const AUTH_SESSION_COOKIE = "backoffice_auth_session";

export type AuthSession = {
  accessToken: string;
  refreshToken: string;
  tokenType: string;
  tenantId: string;
  userId: number;
  email: string;
  userStatus: string;
  membershipRole: string;
  membershipStatus: string;
  permissions: string[];
};

type BackendAuthTokenResponse = {
  accessToken: string;
  refreshToken: string;
  tokenType: string;
  expiresIn: number;
};

type BackendAuthMeResponse = {
  userId: number;
  tenantId: string;
  email: string;
  userStatus: string;
  membershipRole: string;
  membershipStatus: string;
  permissions: string[];
};

const DEFAULT_BACKEND_BASE_URL = "http://localhost:8080";

function getBackendBaseUrl(): string {
  return process.env.BACKEND_API_URL?.trim() || DEFAULT_BACKEND_BASE_URL;
}

function encodeSession(session: AuthSession): string {
  return Buffer.from(JSON.stringify(session), "utf8").toString("base64url");
}

function decodeSession(value: string): AuthSession | null {
  try {
    const parsed = JSON.parse(Buffer.from(value, "base64url").toString("utf8")) as AuthSession;
    if (!parsed.accessToken || !parsed.refreshToken || !parsed.tenantId || !parsed.membershipRole) {
      return null;
    }
    return parsed;
  } catch {
    return null;
  }
}

function buildCorrelationId(prefix: string): string {
  return `${prefix}-${Date.now()}-${Math.random().toString(36).slice(2)}`;
}

function buildBackendAuthUrl(path: string): string {
  const normalizedPath = path.startsWith("/") ? path : `/${path}`;
  return new URL(normalizedPath, getBackendBaseUrl()).toString();
}

async function backendJson<T>(path: string, init: RequestInit): Promise<{ status: number; payload: T }> {
  const response = await fetch(buildBackendAuthUrl(path), {
    cache: "no-store",
    ...init
  });
  const payload = (await response.json()) as T;
  return { status: response.status, payload };
}

export function readAuthSession(request: NextRequest): AuthSession | null {
  const cookieValue = request.cookies.get(AUTH_SESSION_COOKIE)?.value;
  return cookieValue ? decodeSession(cookieValue) : null;
}

export function isAuthSession(payload: AuthSession | Record<string, unknown>): payload is AuthSession {
  return typeof payload.accessToken === "string"
    && typeof payload.refreshToken === "string"
    && typeof payload.tenantId === "string"
    && typeof payload.membershipRole === "string";
}

export function writeAuthSession(response: NextResponse, session: AuthSession) {
  response.cookies.set(AUTH_SESSION_COOKIE, encodeSession(session), {
    httpOnly: true,
    sameSite: "lax",
    secure: false,
    path: "/",
    maxAge: 60 * 60 * 24 * 7
  });
}

export function clearAuthSession(response: NextResponse) {
  response.cookies.set(AUTH_SESSION_COOKIE, "", {
    httpOnly: true,
    sameSite: "lax",
    secure: false,
    path: "/",
    expires: new Date(0)
  });
}

export async function loginWithBackend(payload: {
  tenantId: string;
  email: string;
  password: string;
  deviceInfo?: string;
}): Promise<{ status: number; payload: AuthSession | Record<string, unknown> }> {
  const tokenResult = await backendJson<BackendAuthTokenResponse | Record<string, unknown>>("/auth/login", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-Correlation-Id": buildCorrelationId("web-auth-login")
    },
    body: JSON.stringify(payload)
  });

  if (tokenResult.status >= 400) {
    return tokenResult as { status: number; payload: Record<string, unknown> };
  }

  const tokens = tokenResult.payload as BackendAuthTokenResponse;
  const meResult = await backendJson<BackendAuthMeResponse | Record<string, unknown>>("/auth/me", {
    method: "GET",
    headers: {
      Authorization: `Bearer ${tokens.accessToken}`,
      "X-Correlation-Id": buildCorrelationId("web-auth-me")
    }
  });

  if (meResult.status >= 400) {
    return meResult as { status: number; payload: Record<string, unknown> };
  }

  const me = meResult.payload as BackendAuthMeResponse;
  return {
    status: 200,
    payload: {
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      tokenType: tokens.tokenType,
      tenantId: me.tenantId,
      userId: me.userId,
      email: me.email,
      userStatus: me.userStatus,
      membershipRole: me.membershipRole,
      membershipStatus: me.membershipStatus,
      permissions: me.permissions
    }
  };
}

export async function logoutWithBackend(session: AuthSession): Promise<void> {
  await backendJson<void>("/auth/logout", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-Correlation-Id": buildCorrelationId("web-auth-logout")
    },
    body: JSON.stringify({ refreshToken: session.refreshToken })
  });
}

export function unauthorizedJson(message = "Authentication required") {
  return NextResponse.json({ error: message }, { status: 401 });
}

export function forbiddenJson(message = "Insufficient permissions") {
  return NextResponse.json({ error: message }, { status: 403 });
}

export function requirePlatformAdmin(session: AuthSession): NextResponse | null {
  if (session.membershipRole !== "PLATFORM_ADMIN" || session.membershipStatus !== "ACTIVE") {
    return forbiddenJson("PLATFORM_ADMIN role required");
  }
  return null;
}

export function buildAuthenticatedHeaders(session: AuthSession, correlationPrefix: string, initHeaders?: HeadersInit): Headers {
  const headers = new Headers(initHeaders ?? {});
  if (!headers.has("Content-Type")) {
    headers.set("Content-Type", "application/json");
  }
  headers.set("Authorization", `Bearer ${session.accessToken}`);
  headers.set("X-Tenant-Id", session.tenantId);
  headers.set("X-Actor-Id", String(session.userId));
  headers.set("X-Actor-Role", session.membershipRole.toLowerCase());
  if (!headers.has("X-Correlation-Id")) {
    headers.set("X-Correlation-Id", buildCorrelationId(correlationPrefix));
  }
  return headers;
}
