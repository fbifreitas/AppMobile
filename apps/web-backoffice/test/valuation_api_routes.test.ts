import assert from "node:assert/strict";
import test from "node:test";

import { NextRequest } from "next/server";
import { GET as valuationGet, POST as valuationPost } from "../app/api/valuation/processes/route";
import { GET as valuationDetailGet } from "../app/api/valuation/processes/[processId]/route";
import { POST as intakeValidationPost } from "../app/api/valuation/processes/[processId]/validate-intake/route";

function makeJsonResponse(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json"
    }
  });
}

function sessionCookie(tenantId = "tenant-alpha"): string {
  return `backoffice_auth_session=${Buffer.from(JSON.stringify({
    accessToken: "access-token",
    refreshToken: "refresh-token",
    tokenType: "Bearer",
    tenantId,
    userId: 77,
    email: "analyst@compass.com",
    userStatus: "APPROVED",
    membershipRole: "TENANT_ADMIN",
    membershipStatus: "ACTIVE",
    permissions: ["valuation:*"]
  }), "utf8").toString("base64url")}`;
}

test("valuation list route forwards filters to backend", async () => {
  const originalFetch = globalThis.fetch;
  let capturedUrl = "";

  globalThis.fetch = async (input) => {
    capturedUrl = String(input);
    return makeJsonResponse(200, {
      total: 1,
      items: [{ id: 10, inspectionId: 22, status: "PENDING_INTAKE" }]
    });
  };

  try {
    const request = new NextRequest("http://localhost/api/valuation/processes?tenantId=ignored&status=PENDING_INTAKE", {
      headers: {
        cookie: sessionCookie()
      }
    });
    const response = await valuationGet(request);
    const payload = (await response.json()) as { total: number };

    assert.equal(response.status, 200);
    assert.equal(payload.total, 1);
    assert.match(capturedUrl, /tenantId=tenant-alpha/);
    assert.match(capturedUrl, /status=PENDING_INTAKE/);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("valuation list route exige sessao autenticada", async () => {
  const originalFetch = globalThis.fetch;
  let called = false;

  globalThis.fetch = async () => {
    called = true;
    return makeJsonResponse(200, {});
  };

  try {
    const request = new NextRequest("http://localhost/api/valuation/processes?tenantId=tenant-alpha");
    const response = await valuationGet(request);
    const payload = (await response.json()) as { error: string };

    assert.equal(response.status, 401);
    assert.equal(payload.error, "Authentication required");
    assert.equal(called, false);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("valuation create route proxies payload to backend", async () => {
  const originalFetch = globalThis.fetch;
  let capturedMethod = "";
  let capturedBody = "";

  globalThis.fetch = async (_input, init) => {
    capturedMethod = String(init?.method);
    capturedBody = String(init?.body);
    return makeJsonResponse(201, { id: 44, status: "PENDING_INTAKE" });
  };

  try {
    const request = new NextRequest("http://localhost/api/valuation/processes?tenantId=ignored", {
      method: "POST",
      body: JSON.stringify({ inspectionId: 19, method: "BASIC" }),
      headers: {
        "Content-Type": "application/json",
        cookie: sessionCookie()
      }
    });
    const response = await valuationPost(request);
    const payload = (await response.json()) as { id: number };

    assert.equal(response.status, 201);
    assert.equal(payload.id, 44);
    assert.equal(capturedMethod, "POST");
    assert.match(capturedBody, /"inspectionId":19/);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("valuation detail route proxies the process id", async () => {
  const originalFetch = globalThis.fetch;
  let capturedUrl = "";

  globalThis.fetch = async (input) => {
    capturedUrl = String(input);
    return makeJsonResponse(200, { id: 77, status: "INTAKE_VALIDATED" });
  };

  try {
    const request = new NextRequest("http://localhost/api/valuation/processes/77?tenantId=ignored", {
      headers: {
        cookie: sessionCookie()
      }
    });
    const response = await valuationDetailGet(request, {
      params: { processId: "77" }
    });
    const payload = (await response.json()) as { id: number };

    assert.equal(response.status, 200);
    assert.equal(payload.id, 77);
    assert.match(capturedUrl, /valuation\/processes\/77/);
    assert.match(capturedUrl, /tenantId=tenant-alpha/);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("intake validation route proxies body to backend", async () => {
  const originalFetch = globalThis.fetch;
  let capturedBody = "";
  let capturedUrl = "";

  globalThis.fetch = async (input, init) => {
    capturedUrl = String(input);
    capturedBody = String(init?.body);
    return makeJsonResponse(200, { id: 77, status: "INTAKE_VALIDATED" });
  };

  try {
    const request = new NextRequest("http://localhost/api/valuation/processes/77/validate-intake?tenantId=ignored", {
      method: "POST",
      body: JSON.stringify({ result: "VALIDATED", issues: [], notes: "ok" }),
      headers: {
        "Content-Type": "application/json",
        cookie: sessionCookie()
      }
    });
    const response = await intakeValidationPost(request, {
      params: { processId: "77" }
    });
    const payload = (await response.json()) as { status: string };

    assert.equal(response.status, 200);
    assert.equal(payload.status, "INTAKE_VALIDATED");
    assert.match(capturedBody, /"result":"VALIDATED"/);
    assert.match(capturedUrl, /tenantId=tenant-alpha/);
  } finally {
    globalThis.fetch = originalFetch;
  }
});
