import assert from "node:assert/strict";
import test from "node:test";

import { NextRequest } from "next/server";
import { GET as jobsGet } from "../app/api/jobs/route";
import { GET as jobDetailGet } from "../app/api/jobs/[jobId]/route";
import { GET as jobTimelineGet } from "../app/api/jobs/[jobId]/timeline/route";
import { POST as jobAssignPost } from "../app/api/jobs/[jobId]/assign/route";
import { POST as jobCancelPost } from "../app/api/jobs/[jobId]/cancel/route";
import { POST as casesPost } from "../app/api/cases/route";

function makeJsonResponse(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json"
    }
  });
}

function sessionCookie(tenantId = "tenant-alpha", userId = 77): string {
  return `backoffice_auth_session=${Buffer.from(JSON.stringify({
    accessToken: "access-token",
    refreshToken: "refresh-token",
    tokenType: "Bearer",
    tenantId,
    userId,
    email: "operator@compass.com",
    userStatus: "APPROVED",
    membershipRole: "TENANT_ADMIN",
    membershipStatus: "ACTIVE",
    permissions: ["jobs:*"]
  }), "utf8").toString("base64url")}`;
}

test("jobs route propaga filtros e cabecalhos obrigatorios", async () => {
  const originalFetch = globalThis.fetch;
  let capturedUrl = "";
  let capturedHeaders: Headers | undefined;

  globalThis.fetch = async (input, init) => {
    capturedUrl = String(input);
    capturedHeaders = new Headers(init?.headers);
    return makeJsonResponse(200, {
      content: [{ id: 11, status: "ELIGIBLE_FOR_DISPATCH" }],
      totalElements: 1
    });
  };

  try {
    const request = new NextRequest("http://localhost/api/jobs?tenantId=ignored&actorId=ignored&status=OFFERED&page=1&size=10", {
      headers: {
        cookie: sessionCookie()
      }
    });
    const response = await jobsGet(request);
    const payload = (await response.json()) as { totalElements: number };

    assert.equal(response.status, 200);
    assert.equal(payload.totalElements, 1);
    assert.match(capturedUrl, /\/api\/jobs\?/);
    assert.match(capturedUrl, /status=OFFERED/);
    assert.match(capturedUrl, /page=1/);
    assert.match(capturedUrl, /size=10/);
    assert.equal(capturedHeaders?.get("X-Tenant-Id"), "tenant-alpha");
    assert.equal(capturedHeaders?.get("X-Actor-Id"), "77");
    assert.equal(capturedHeaders?.get("Authorization"), "Bearer access-token");
    assert.match(capturedHeaders?.get("X-Correlation-Id") ?? "", /^jobs-list-/);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("jobs route exige sessao autenticada", async () => {
  const originalFetch = globalThis.fetch;
  let called = false;

  globalThis.fetch = async () => {
    called = true;
    return makeJsonResponse(200, {});
  };

  try {
    const request = new NextRequest("http://localhost/api/jobs?tenantId=tenant-alpha");
    const response = await jobsGet(request);
    const payload = (await response.json()) as { error: string };

    assert.equal(response.status, 401);
    assert.equal(payload.error, "Authentication required");
    assert.equal(called, false);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("job detail route propaga id do job", async () => {
  const originalFetch = globalThis.fetch;
  let capturedUrl = "";

  globalThis.fetch = async (input) => {
    capturedUrl = String(input);
    return makeJsonResponse(200, { id: 9, status: "OFFERED" });
  };

  try {
    const request = new NextRequest("http://localhost/api/jobs/9?tenantId=ignored", {
      headers: {
        cookie: sessionCookie()
      }
    });
    const response = await jobDetailGet(request, {
      params: Promise.resolve({ jobId: "9" })
    });
    const payload = (await response.json()) as { id: number };

    assert.equal(response.status, 200);
    assert.equal(payload.id, 9);
    assert.match(capturedUrl, /\/api\/jobs\/9$/);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("job timeline route consulta timeline do backend", async () => {
  const originalFetch = globalThis.fetch;
  let capturedUrl = "";

  globalThis.fetch = async (input) => {
    capturedUrl = String(input);
    return makeJsonResponse(200, { jobId: 9, entries: [] });
  };

  try {
    const request = new NextRequest("http://localhost/api/jobs/9/timeline?tenantId=ignored", {
      headers: {
        cookie: sessionCookie()
      }
    });
    const response = await jobTimelineGet(request, {
      params: Promise.resolve({ jobId: "9" })
    });
    const payload = (await response.json()) as { jobId: number };

    assert.equal(response.status, 200);
    assert.equal(payload.jobId, 9);
    assert.match(capturedUrl, /\/api\/jobs\/9\/timeline$/);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("job assign route envia payload ao backend", async () => {
  const originalFetch = globalThis.fetch;
  let capturedBody = "";

  globalThis.fetch = async (_, init) => {
    capturedBody = String(init?.body);
    return makeJsonResponse(200, { id: 15, assignedTo: 44, status: "OFFERED" });
  };

  try {
    const request = new NextRequest("http://localhost/api/jobs/15/assign?tenantId=ignored", {
      method: "POST",
      body: JSON.stringify({ userId: 44 }),
      headers: {
        "Content-Type": "application/json",
        cookie: sessionCookie()
      }
    });
    const response = await jobAssignPost(request, {
      params: Promise.resolve({ jobId: "15" })
    });
    const payload = (await response.json()) as { assignedTo: number };

    assert.equal(response.status, 200);
    assert.equal(payload.assignedTo, 44);
    assert.match(capturedBody, /"userId":44/);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("job cancel route aceita motivo opcional", async () => {
  const originalFetch = globalThis.fetch;
  let capturedBody = "";

  globalThis.fetch = async (_, init) => {
    capturedBody = String(init?.body);
    return makeJsonResponse(200, { id: 15, status: "CLOSED" });
  };

  try {
    const request = new NextRequest("http://localhost/api/jobs/15/cancel?tenantId=ignored", {
      method: "POST",
      body: JSON.stringify({ reason: "cliente desistiu" }),
      headers: {
        "Content-Type": "application/json",
        cookie: sessionCookie()
      }
    });
    const response = await jobCancelPost(request, {
      params: Promise.resolve({ jobId: "15" })
    });
    const payload = (await response.json()) as { status: string };

    assert.equal(response.status, 200);
    assert.equal(payload.status, "CLOSED");
    assert.match(capturedBody, /cliente desistiu/);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("cases route envia criacao minima ao backend", async () => {
  const originalFetch = globalThis.fetch;
  let capturedBody = "";

  globalThis.fetch = async (_, init) => {
    capturedBody = String(init?.body);
    return makeJsonResponse(201, {
      caseId: 100,
      caseNumber: "CASE-2026-001",
      jobId: 200,
      jobStatus: "ELIGIBLE_FOR_DISPATCH"
    });
  };

  try {
    const request = new NextRequest("http://localhost/api/cases?tenantId=ignored&actorId=ignored", {
      method: "POST",
      body: JSON.stringify({
        number: "CASE-2026-001",
        propertyAddress: "Rua Exemplo, 100",
        inspectionType: "ENTRY",
        deadline: "2026-04-05T12:00:00.000Z",
        jobTitle: "Vistoria inicial"
      }),
      headers: {
        "Content-Type": "application/json",
        cookie: sessionCookie()
      }
    });
    const response = await casesPost(request);
    const payload = (await response.json()) as { caseId: number };

    assert.equal(response.status, 201);
    assert.equal(payload.caseId, 100);
    assert.match(capturedBody, /CASE-2026-001/);
    assert.match(capturedBody, /Vistoria inicial/);
  } finally {
    globalThis.fetch = originalFetch;
  }
});
