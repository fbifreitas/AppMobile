import assert from "node:assert/strict";
import test from "node:test";

import { NextRequest } from "next/server";
import { GET as controlTowerGet } from "../app/api/operations/control-tower/route";
import { POST as retentionPost } from "../app/api/operations/control-tower/retention/run/route";

function makeJsonResponse(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json"
    }
  });
}

test("control tower route forwards tenant filter to backend", async () => {
  const originalFetch = globalThis.fetch;
  let capturedUrl = "";

  globalThis.fetch = async (input) => {
    capturedUrl = String(input);
    return makeJsonResponse(200, {
      generatedAt: "2026-04-08T20:10:00Z",
      overview: { totalRequests24h: 4, alertCount: 1 }
    });
  };

  try {
    const request = new NextRequest("http://localhost/api/operations/control-tower?tenantId=tenant-alpha");
    const response = await controlTowerGet(request);
    const payload = (await response.json()) as { overview: { totalRequests24h: number } };

    assert.equal(response.status, 200);
    assert.equal(payload.overview.totalRequests24h, 4);
    assert.match(capturedUrl, /backoffice\/operations\/control-tower/);
    assert.match(capturedUrl, /tenantId=tenant-alpha/);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("control tower retention route proxies POST to backend", async () => {
  const originalFetch = globalThis.fetch;
  let capturedMethod = "";
  let capturedUrl = "";

  globalThis.fetch = async (input, init) => {
    capturedUrl = String(input);
    capturedMethod = String(init?.method);
    return makeJsonResponse(200, { deletedEvents: 2 });
  };

  try {
    const request = new NextRequest("http://localhost/api/operations/control-tower/retention/run?tenantId=tenant-alpha", {
      method: "POST",
      headers: {
        "X-Actor-Id": "9001"
      }
    });
    const response = await retentionPost(request);
    const payload = (await response.json()) as { deletedEvents: number };

    assert.equal(response.status, 200);
    assert.equal(payload.deletedEvents, 2);
    assert.equal(capturedMethod, "POST");
    assert.match(capturedUrl, /backoffice\/operations\/control-tower\/retention\/run/);
  } finally {
    globalThis.fetch = originalFetch;
  }
});
