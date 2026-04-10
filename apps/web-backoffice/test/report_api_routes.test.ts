import assert from "node:assert/strict";
import test from "node:test";

import { NextRequest } from "next/server";
import { GET as reportsGet } from "../app/api/reports/route";
import { POST as generateReportPost } from "../app/api/reports/generate/[valuationProcessId]/route";
import { GET as reportDetailGet } from "../app/api/reports/[reportId]/route";
import { POST as reviewReportPost } from "../app/api/reports/[reportId]/review/route";

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
    email: "reviewer@compass.com",
    userStatus: "APPROVED",
    membershipRole: "TENANT_ADMIN",
    membershipStatus: "ACTIVE",
    permissions: ["reports:*"]
  }), "utf8").toString("base64url")}`;
}

test("report list route forwards filters to backend", async () => {
  const originalFetch = globalThis.fetch;
  let capturedUrl = "";

  globalThis.fetch = async (input) => {
    capturedUrl = String(input);
    return makeJsonResponse(200, {
      total: 1,
      items: [{ id: 5, valuationProcessId: 77, status: "GENERATED" }]
    });
  };

  try {
    const request = new NextRequest("http://localhost/api/reports?tenantId=ignored&status=GENERATED", {
      headers: {
        cookie: sessionCookie()
      }
    });
    const response = await reportsGet(request);
    const payload = (await response.json()) as { total: number };

    assert.equal(response.status, 200);
    assert.equal(payload.total, 1);
    assert.match(capturedUrl, /tenantId=tenant-alpha/);
    assert.match(capturedUrl, /status=GENERATED/);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("report list route exige sessao autenticada", async () => {
  const originalFetch = globalThis.fetch;
  let called = false;

  globalThis.fetch = async () => {
    called = true;
    return makeJsonResponse(200, {});
  };

  try {
    const request = new NextRequest("http://localhost/api/reports?tenantId=tenant-alpha");
    const response = await reportsGet(request);
    const payload = (await response.json()) as { error: string };

    assert.equal(response.status, 401);
    assert.equal(payload.error, "Authentication required");
    assert.equal(called, false);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("report generate route proxies process id and body", async () => {
  const originalFetch = globalThis.fetch;
  let capturedUrl = "";
  let capturedMethod = "";

  globalThis.fetch = async (input, init) => {
    capturedUrl = String(input);
    capturedMethod = String(init?.method);
    return makeJsonResponse(201, { id: 9, status: "GENERATED" });
  };

  try {
    const request = new NextRequest("http://localhost/api/reports/generate/77?tenantId=ignored", {
      method: "POST",
      body: JSON.stringify({}),
      headers: {
        "Content-Type": "application/json",
        cookie: sessionCookie()
      }
    });
    const response = await generateReportPost(request, {
      params: Promise.resolve({ valuationProcessId: "77" })
    });
    const payload = (await response.json()) as { id: number };

    assert.equal(response.status, 201);
    assert.equal(payload.id, 9);
    assert.equal(capturedMethod, "POST");
    assert.match(capturedUrl, /reports\/77\/generate/);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("report detail route proxies the report id", async () => {
  const originalFetch = globalThis.fetch;
  let capturedUrl = "";

  globalThis.fetch = async (input) => {
    capturedUrl = String(input);
    return makeJsonResponse(200, { id: 91, status: "READY_FOR_SIGN" });
  };

  try {
    const request = new NextRequest("http://localhost/api/reports/91?tenantId=ignored", {
      headers: {
        cookie: sessionCookie()
      }
    });
    const response = await reportDetailGet(request, {
      params: Promise.resolve({ reportId: "91" })
    });
    const payload = (await response.json()) as { id: number };

    assert.equal(response.status, 200);
    assert.equal(payload.id, 91);
    assert.match(capturedUrl, /backoffice\/reports\/91/);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("report review route proxies body to backend", async () => {
  const originalFetch = globalThis.fetch;
  let capturedBody = "";

  globalThis.fetch = async (_input, init) => {
    capturedBody = String(init?.body);
    return makeJsonResponse(200, { id: 91, status: "READY_FOR_SIGN" });
  };

  try {
    const request = new NextRequest("http://localhost/api/reports/91/review?tenantId=ignored", {
      method: "POST",
      body: JSON.stringify({ action: "APPROVE", notes: "ship it" }),
      headers: {
        "Content-Type": "application/json",
        cookie: sessionCookie()
      }
    });
    const response = await reviewReportPost(request, {
      params: Promise.resolve({ reportId: "91" })
    });
    const payload = (await response.json()) as { status: string };

    assert.equal(response.status, 200);
    assert.equal(payload.status, "READY_FOR_SIGN");
    assert.match(capturedBody, /"action":"APPROVE"/);
  } finally {
    globalThis.fetch = originalFetch;
  }
});
