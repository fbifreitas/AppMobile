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
    const request = new NextRequest("http://localhost/api/valuation/processes?tenantId=tenant-alpha&status=PENDING_INTAKE");
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
    const request = new NextRequest("http://localhost/api/valuation/processes?tenantId=tenant-alpha", {
      method: "POST",
      body: JSON.stringify({ inspectionId: 19, method: "BASIC" }),
      headers: {
        "Content-Type": "application/json"
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
    const request = new NextRequest("http://localhost/api/valuation/processes/77?tenantId=tenant-alpha");
    const response = await valuationDetailGet(request, {
      params: Promise.resolve({ processId: "77" })
    });
    const payload = (await response.json()) as { id: number };

    assert.equal(response.status, 200);
    assert.equal(payload.id, 77);
    assert.match(capturedUrl, /valuation\/processes\/77/);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("intake validation route proxies body to backend", async () => {
  const originalFetch = globalThis.fetch;
  let capturedBody = "";

  globalThis.fetch = async (_input, init) => {
    capturedBody = String(init?.body);
    return makeJsonResponse(200, { id: 77, status: "INTAKE_VALIDATED" });
  };

  try {
    const request = new NextRequest("http://localhost/api/valuation/processes/77/validate-intake?tenantId=tenant-alpha", {
      method: "POST",
      body: JSON.stringify({ result: "VALIDATED", issues: [], notes: "ok" }),
      headers: {
        "Content-Type": "application/json"
      }
    });
    const response = await intakeValidationPost(request, {
      params: Promise.resolve({ processId: "77" })
    });
    const payload = (await response.json()) as { status: string };

    assert.equal(response.status, 200);
    assert.equal(payload.status, "INTAKE_VALIDATED");
    assert.match(capturedBody, /"result":"VALIDATED"/);
  } finally {
    globalThis.fetch = originalFetch;
  }
});
