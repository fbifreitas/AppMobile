import assert from "node:assert/strict";
import test from "node:test";

import { NextRequest } from "next/server";
import { GET as listTenants, POST as createTenant } from "../app/api/platform/tenants/route";
import { PUT as putAdminHandoff } from "../app/api/platform/tenants/[tenantId]/admin-handoff/route";
import { PUT as putApplication } from "../app/api/platform/tenants/[tenantId]/application/route";
import { PUT as putLicense } from "../app/api/platform/tenants/[tenantId]/license/route";

const session = {
  accessToken: "access-token",
  refreshToken: "refresh-token",
  tokenType: "Bearer",
  tenantId: "tenant-compass",
  userId: 42,
  email: "platform@kaptu.com",
  userStatus: "APPROVED",
  membershipRole: "PLATFORM_ADMIN",
  membershipStatus: "ACTIVE",
  permissions: ["platform:*"]
};

function sessionCookie(): string {
  return `backoffice_auth_session=${Buffer.from(JSON.stringify(session), "utf8").toString("base64url")}`;
}

function tenantAdminSessionCookie(): string {
  return `backoffice_auth_session=${Buffer.from(JSON.stringify({
    ...session,
    membershipRole: "TENANT_ADMIN",
    permissions: ["users:manage"]
  }), "utf8").toString("base64url")}`;
}

function makeJsonResponse(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json"
    }
  });
}

test("platform tenant list route proxies platform admin request", async () => {
  const originalFetch = globalThis.fetch;
  let capturedUrl = "";

  globalThis.fetch = async (input) => {
    capturedUrl = String(input);
    return makeJsonResponse(200, { total: 1, items: [] });
  };

  try {
    const request = new NextRequest("http://localhost/api/platform/tenants?q=compass", {
      headers: {
        cookie: sessionCookie()
      }
    });
    const response = await listTenants(request);
    const payload = (await response.json()) as { total: number };

    assert.equal(response.status, 200);
    assert.equal(payload.total, 1);
    assert.match(capturedUrl, /backoffice\/platform\/tenants/);
    assert.match(capturedUrl, /actorRole=platform_admin/);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("platform tenant routes reject non platform admin session before proxying", async () => {
  const originalFetch = globalThis.fetch;
  let called = false;

  globalThis.fetch = async () => {
    called = true;
    return makeJsonResponse(200, { total: 1, items: [] });
  };

  try {
    const request = new NextRequest("http://localhost/api/platform/tenants", {
      headers: {
        cookie: tenantAdminSessionCookie()
      }
    });
    const response = await listTenants(request);
    const payload = (await response.json()) as { error: string };

    assert.equal(response.status, 403);
    assert.equal(payload.error, "PLATFORM_ADMIN role required");
    assert.equal(called, false);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("platform tenant create route proxies POST payload", async () => {
  const originalFetch = globalThis.fetch;
  let capturedMethod = "";
  let capturedBody = "";

  globalThis.fetch = async (_input, init) => {
    capturedMethod = String(init?.method);
    capturedBody = String(init?.body);
    return makeJsonResponse(200, { tenantId: "tenant-nova-empresa", slug: "nova-empresa" });
  };

  try {
    const request = new NextRequest("http://localhost/api/platform/tenants", {
      method: "POST",
      headers: {
        cookie: sessionCookie()
      },
      body: JSON.stringify({
        tenantId: "tenant-nova-empresa",
        slug: "nova-empresa",
        displayName: "Nova Empresa",
        status: "ACTIVE"
      })
    });
    const response = await createTenant(request);
    const payload = (await response.json()) as { tenantId: string; slug: string };

    assert.equal(response.status, 200);
    assert.equal(payload.tenantId, "tenant-nova-empresa");
    assert.equal(capturedMethod, "POST");
    assert.match(capturedBody, /nova-empresa/);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("tenant application route proxies PUT payload", async () => {
  const originalFetch = globalThis.fetch;
  let capturedMethod = "";
  let capturedBody = "";

  globalThis.fetch = async (_input, init) => {
    capturedMethod = String(init?.method);
    capturedBody = String(init?.body);
    return makeJsonResponse(200, { appCode: "compass" });
  };

  try {
    const request = new NextRequest("http://localhost/api/platform/tenants/tenant-compass/application", {
      method: "PUT",
      headers: {
        cookie: sessionCookie()
      },
      body: JSON.stringify({
        appCode: "compass",
        brandName: "Compass",
        displayName: "Compass",
        applicationId: "br.com.compass",
        bundleId: "br.com.compass",
        status: "ACTIVE"
      })
    });
    const response = await putApplication(request, { params: { tenantId: "tenant-compass" } });
    const payload = (await response.json()) as { appCode: string };

    assert.equal(response.status, 200);
    assert.equal(payload.appCode, "compass");
    assert.equal(capturedMethod, "PUT");
    assert.match(capturedBody, /br\.com\.compass/);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("tenant license route proxies PUT payload", async () => {
  const originalFetch = globalThis.fetch;
  let capturedMethod = "";
  let capturedBody = "";

  globalThis.fetch = async (_input, init) => {
    capturedMethod = String(init?.method);
    capturedBody = String(init?.body);
    return makeJsonResponse(200, { contractedSeats: 15 });
  };

  try {
    const request = new NextRequest("http://localhost/api/platform/tenants/tenant-compass/license", {
      method: "PUT",
      headers: {
        cookie: sessionCookie()
      },
      body: JSON.stringify({
        licenseModel: "PER_USER",
        contractedSeats: 15,
        warningSeats: 12,
        hardLimitEnforced: true
      })
    });
    const response = await putLicense(request, { params: { tenantId: "tenant-compass" } });
    const payload = (await response.json()) as { contractedSeats: number };

    assert.equal(response.status, 200);
    assert.equal(payload.contractedSeats, 15);
    assert.equal(capturedMethod, "PUT");
    assert.match(capturedBody, /\"contractedSeats\":15/);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("tenant admin handoff route proxies PUT payload", async () => {
  const originalFetch = globalThis.fetch;
  let capturedMethod = "";
  let capturedBody = "";

  globalThis.fetch = async (_input, init) => {
    capturedMethod = String(init?.method);
    capturedBody = String(init?.body);
    return makeJsonResponse(200, { credentialProvisioned: true });
  };

  try {
    const request = new NextRequest("http://localhost/api/platform/tenants/tenant-compass/admin-handoff", {
      method: "PUT",
      headers: {
        cookie: sessionCookie()
      },
      body: JSON.stringify({
        email: "admin@compass.com",
        nome: "Compass Admin",
        tipo: "PJ",
        temporaryPassword: "Compass@123"
      })
    });
    const response = await putAdminHandoff(request, { params: { tenantId: "tenant-compass" } });
    const payload = (await response.json()) as { credentialProvisioned: boolean };

    assert.equal(response.status, 200);
    assert.equal(payload.credentialProvisioned, true);
    assert.equal(capturedMethod, "PUT");
    assert.match(capturedBody, /Compass@123/);
  } finally {
    globalThis.fetch = originalFetch;
  }
});
