import assert from "node:assert/strict";
import test from "node:test";

import { NextRequest } from "next/server";
import { GET as inspectionsGet } from "../app/api/inspections/route";
import { GET as inspectionDetailGet, POST as inspectionDetailPost } from "../app/api/inspections/[inspectionId]/route";

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
    email: "operator@compass.com",
    userStatus: "APPROVED",
    membershipRole: "TENANT_ADMIN",
    membershipStatus: "ACTIVE",
    permissions: ["inspections:*"]
  }), "utf8").toString("base64url")}`;
}

test("inspections route propaga query params e resposta do backend", async () => {
  const originalFetch = globalThis.fetch;
  let capturedUrl = "";
  let capturedHeaders: Headers | undefined;

  globalThis.fetch = async (input, init) => {
    capturedUrl = String(input);
    capturedHeaders = new Headers(init?.headers);
    return makeJsonResponse(200, {
      page: 0,
      size: 20,
      total: 1,
      items: [{ id: 1, protocolId: "INS-001", status: "SUBMITTED" }]
    });
  };

  try {
    const request = new NextRequest("http://localhost/api/inspections?tenantId=ignored&status=SUBMITTED&fieldAgentId=42&page=1&size=10", {
      headers: {
        cookie: sessionCookie()
      }
    });
    const response = await inspectionsGet(request);
    const payload = (await response.json()) as { total: number };

    assert.equal(response.status, 200);
    assert.equal(payload.total, 1);
    assert.match(capturedUrl, /tenantId=tenant-alpha/);
    assert.match(capturedUrl, /status=SUBMITTED/);
    assert.match(capturedUrl, /fieldAgentId=42/);
    assert.match(capturedUrl, /page=1/);
    assert.match(capturedUrl, /size=10/);
    assert.equal(capturedHeaders?.get("Authorization"), "Bearer access-token");
    assert.equal(capturedHeaders?.get("X-Tenant-Id"), "tenant-alpha");
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("inspections route exige sessao autenticada", async () => {
  const originalFetch = globalThis.fetch;
  let called = false;

  globalThis.fetch = async () => {
    called = true;
    return makeJsonResponse(200, {});
  };

  try {
    const request = new NextRequest("http://localhost/api/inspections?tenantId=tenant-alpha");
    const response = await inspectionsGet(request);
    const payload = (await response.json()) as { error: string };

    assert.equal(response.status, 401);
    assert.equal(payload.error, "Authentication required");
    assert.equal(called, false);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("inspection detail route propaga detalhe do backend", async () => {
  const originalFetch = globalThis.fetch;
  let capturedUrl = "";

  globalThis.fetch = async (input) => {
    capturedUrl = String(input);
    return makeJsonResponse(200, {
      id: 9,
      protocolId: "INS-009",
      status: "SUBMITTED"
    });
  };

  try {
    const request = new NextRequest("http://localhost/api/inspections/9?tenantId=ignored", {
      headers: {
        cookie: sessionCookie()
      }
    });
    const response = await inspectionDetailGet(request, {
      params: { inspectionId: "9" }
    });
    const payload = (await response.json()) as { id: number };

    assert.equal(response.status, 200);
    assert.equal(payload.id, 9);
    assert.match(capturedUrl, /\/9\?/);
    assert.match(capturedUrl, /tenantId=tenant-alpha/);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("inspection detail post propaga classificacao manual para o backend", async () => {
  const originalFetch = globalThis.fetch;
  let capturedUrl = "";
  let capturedBody = "";
  let capturedHeaders: Headers | undefined;

  globalThis.fetch = async (input, init) => {
    capturedUrl = String(input);
    capturedBody = String(init?.body ?? "");
    capturedHeaders = new Headers(init?.headers);
    return makeJsonResponse(200, {
      id: 9,
      protocolId: "INS-009",
      status: "SUBMITTED"
    });
  };

  try {
    const request = new NextRequest("http://localhost/api/inspections/9", {
      method: "POST",
      headers: {
        cookie: sessionCookie()
      },
      body: JSON.stringify({
        captures: [{ filePath: "capture-1.jpg", macroLocation: "Rua", environmentName: "Fachada" }],
        step2: { ownerPresent: true }
      })
    });
    const response = await inspectionDetailPost(request, {
      params: { inspectionId: "9" }
    });
    const payload = (await response.json()) as { id: number };

    assert.equal(response.status, 200);
    assert.equal(payload.id, 9);
    assert.match(capturedUrl, /\/9\/manual-classification\?/);
    assert.match(capturedBody, /capture-1\.jpg/);
    assert.equal(capturedHeaders?.get("Authorization"), "Bearer access-token");
  } finally {
    globalThis.fetch = originalFetch;
  }
});
