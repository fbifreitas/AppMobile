import assert from "node:assert/strict";
import test from "node:test";

import { NextRequest } from "next/server";
import { GET as inspectionsGet } from "../app/api/inspections/route";
import { GET as inspectionDetailGet } from "../app/api/inspections/[inspectionId]/route";

function makeJsonResponse(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json"
    }
  });
}

test("inspections route propaga query params e resposta do backend", async () => {
  const originalFetch = globalThis.fetch;
  let capturedUrl = "";

  globalThis.fetch = async (input) => {
    capturedUrl = String(input);
    return makeJsonResponse(200, {
      page: 0,
      size: 20,
      total: 1,
      items: [{ id: 1, protocolId: "INS-001", status: "SUBMITTED" }]
    });
  };

  try {
    const request = new NextRequest("http://localhost/api/inspections?tenantId=tenant-alpha&status=SUBMITTED&vistoriadorId=42&page=1&size=10");
    const response = await inspectionsGet(request);
    const payload = (await response.json()) as { total: number };

    assert.equal(response.status, 200);
    assert.equal(payload.total, 1);
    assert.match(capturedUrl, /tenantId=tenant-alpha/);
    assert.match(capturedUrl, /status=SUBMITTED/);
    assert.match(capturedUrl, /vistoriadorId=42/);
    assert.match(capturedUrl, /page=1/);
    assert.match(capturedUrl, /size=10/);
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
    const request = new NextRequest("http://localhost/api/inspections/9?tenantId=tenant-alpha");
    const response = await inspectionDetailGet(request, {
      params: Promise.resolve({ inspectionId: "9" })
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