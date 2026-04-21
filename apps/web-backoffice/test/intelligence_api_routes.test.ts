import assert from "node:assert/strict";
import test from "node:test";

import { NextRequest } from "next/server";
import { GET as analyticsReadinessGet } from "../app/api/intelligence/analytics-readiness/route";
import { POST as triggerEnrichmentPost } from "../app/api/intelligence/cases/[caseId]/enrichment/trigger/route";
import { GET as latestEnrichmentRunGet } from "../app/api/intelligence/cases/[caseId]/enrichment-runs/latest/route";
import { GET as latestExecutionPlanGet } from "../app/api/intelligence/cases/[caseId]/execution-plan/latest/route";
import { GET as manualResolutionQueueGet } from "../app/api/intelligence/manual-resolution-queue/route";
import { GET as reportBasisGet } from "../app/api/intelligence/cases/[caseId]/report-basis/route";
import { GET as referenceProfilesGet } from "../app/api/intelligence/reference-profiles/route";
import { POST as rebuildReferenceProfilesPost } from "../app/api/intelligence/reference-profiles/rebuild/route";
import { GET as captureGatesGet } from "../app/api/intelligence/capture-gates/route";
import { GET as normativeMatrixGet } from "../app/api/intelligence/normative-matrix/route";
import { GET as resolvePreviewGet } from "../app/api/intelligence/cases/[caseId]/resolve-preview/route";

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
    permissions: ["intelligence:*"]
  }), "utf8").toString("base64url")}`;
}

test("manual resolution queue route propagates tenant and auth headers", async () => {
  const originalFetch = globalThis.fetch;
  let capturedUrl = "";
  let capturedHeaders: Headers | undefined;

  globalThis.fetch = async (input, init) => {
    capturedUrl = String(input);
    capturedHeaders = new Headers(init?.headers);
    return makeJsonResponse(200, {
      total: 1,
      items: [{ caseId: 1001, pendingReasons: ["ENRICHMENT_REVIEW_REQUIRED"] }]
    });
  };

  try {
    const request = new NextRequest("http://localhost/api/intelligence/manual-resolution-queue?tenantId=ignored&limit=15", {
      headers: {
        cookie: sessionCookie()
      }
    });
    const response = await manualResolutionQueueGet(request);
    const payload = (await response.json()) as { total: number };

    assert.equal(response.status, 200);
    assert.equal(payload.total, 1);
    assert.match(capturedUrl, /tenantId=tenant-alpha/);
    assert.match(capturedUrl, /limit=15/);
    assert.equal(capturedHeaders?.get("Authorization"), "Bearer access-token");
    assert.equal(capturedHeaders?.get("X-Tenant-Id"), "tenant-alpha");
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("report basis route propagates case path and session tenant", async () => {
  const originalFetch = globalThis.fetch;
  let capturedUrl = "";

  globalThis.fetch = async (input) => {
    capturedUrl = String(input);
    return makeJsonResponse(200, {
      caseId: 99,
      caseNumber: "CASE-99",
      fieldEvidence: []
    });
  };

  try {
    const request = new NextRequest("http://localhost/api/intelligence/cases/99/report-basis?tenantId=ignored", {
      headers: {
        cookie: sessionCookie()
      }
    });
    const response = await reportBasisGet(request, {
      params: { caseId: "99" }
    });
    const payload = (await response.json()) as { caseId: number };

    assert.equal(response.status, 200);
    assert.equal(payload.caseId, 99);
    assert.match(capturedUrl, /cases\/99\/report-basis/);
    assert.match(capturedUrl, /tenantId=tenant-alpha/);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("trigger enrichment route propagates case path and auth headers", async () => {
  const originalFetch = globalThis.fetch;
  let capturedUrl = "";
  let capturedHeaders: Headers | undefined;
  let capturedMethod = "";

  globalThis.fetch = async (input, init) => {
    capturedUrl = String(input);
    capturedHeaders = new Headers(init?.headers);
    capturedMethod = init?.method ?? "GET";
    return makeJsonResponse(202, {
      status: "REVIEW_REQUIRED",
      executionPlan: { status: "REVIEW_REQUIRED" }
    });
  };

  try {
    const request = new NextRequest("http://localhost/api/intelligence/cases/99/enrichment/trigger?tenantId=ignored", {
      method: "POST",
      headers: {
        cookie: sessionCookie()
      }
    });
    const response = await triggerEnrichmentPost(request, {
      params: { caseId: "99" }
    });
    const payload = (await response.json()) as { status: string };

    assert.equal(response.status, 202);
    assert.equal(payload.status, "REVIEW_REQUIRED");
    assert.equal(capturedMethod, "POST");
    assert.match(capturedUrl, /cases\/99\/enrichment\/trigger/);
    assert.match(capturedUrl, /tenantId=tenant-alpha/);
    assert.equal(capturedHeaders?.get("Authorization"), "Bearer access-token");
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("latest enrichment run route propagates case path and session tenant", async () => {
  const originalFetch = globalThis.fetch;
  let capturedUrl = "";
  let capturedHeaders: Headers | undefined;

  globalThis.fetch = async (input, init) => {
    capturedUrl = String(input);
    capturedHeaders = new Headers(init?.headers);
    return makeJsonResponse(200, {
      id: 20,
      status: "COMPLETED"
    });
  };

  try {
    const request = new NextRequest("http://localhost/api/intelligence/cases/32/enrichment-runs/latest", {
      headers: {
        cookie: sessionCookie()
      }
    });
    const response = await latestEnrichmentRunGet(request, {
      params: { caseId: "32" }
    });
    const payload = (await response.json()) as { id: number; status: string };

    assert.equal(response.status, 200);
    assert.equal(payload.id, 20);
    assert.equal(payload.status, "COMPLETED");
    assert.match(capturedUrl, /cases\/32\/enrichment-runs\/latest/);
    assert.match(capturedUrl, /tenantId=tenant-alpha/);
    assert.equal(capturedHeaders?.get("Authorization"), "Bearer access-token");
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("latest execution plan route propagates case path and session tenant", async () => {
  const originalFetch = globalThis.fetch;
  let capturedUrl = "";
  let capturedHeaders: Headers | undefined;

  globalThis.fetch = async (input, init) => {
    capturedUrl = String(input);
    capturedHeaders = new Headers(init?.headers);
    return makeJsonResponse(200, {
      snapshotId: 20,
      status: "PUBLISHED",
      plan: { step1Config: { initialContext: "Rua" } }
    });
  };

  try {
    const request = new NextRequest("http://localhost/api/intelligence/cases/32/execution-plan/latest", {
      headers: {
        cookie: sessionCookie()
      }
    });
    const response = await latestExecutionPlanGet(request, {
      params: { caseId: "32" }
    });
    const payload = (await response.json()) as { snapshotId: number; status: string };

    assert.equal(response.status, 200);
    assert.equal(payload.snapshotId, 20);
    assert.equal(payload.status, "PUBLISHED");
    assert.match(capturedUrl, /cases\/32\/execution-plan\/latest/);
    assert.match(capturedUrl, /tenantId=tenant-alpha/);
    assert.equal(capturedHeaders?.get("Authorization"), "Bearer access-token");
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("analytics readiness route propagates session tenant", async () => {
  const originalFetch = globalThis.fetch;
  let capturedUrl = "";

  globalThis.fetch = async (input) => {
    capturedUrl = String(input);
    return makeJsonResponse(200, {
      enrichmentRuns: 3,
      inspectionReturnArtifacts: 2
    });
  };

  try {
    const request = new NextRequest("http://localhost/api/intelligence/analytics-readiness?tenantId=ignored", {
      headers: {
        cookie: sessionCookie()
      }
    });
    const response = await analyticsReadinessGet(request);
    const payload = (await response.json()) as { enrichmentRuns: number };

    assert.equal(response.status, 200);
    assert.equal(payload.enrichmentRuns, 3);
    assert.match(capturedUrl, /analytics-readiness/);
    assert.match(capturedUrl, /tenantId=tenant-alpha/);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("reference profiles route propagates session tenant and auth headers", async () => {
  const originalFetch = globalThis.fetch;
  let capturedUrl = "";
  let capturedHeaders: Headers | undefined;

  globalThis.fetch = async (input, init) => {
    capturedUrl = String(input);
    capturedHeaders = new Headers(init?.headers);
    return makeJsonResponse(200, {
      total: 2,
      items: [{ id: 1, scopeType: "GLOBAL_REFERENCE" }]
    });
  };

  try {
    const request = new NextRequest("http://localhost/api/intelligence/reference-profiles", {
      headers: {
        cookie: sessionCookie()
      }
    });
    const response = await referenceProfilesGet(request);
    const payload = (await response.json()) as { total: number };

    assert.equal(response.status, 200);
    assert.equal(payload.total, 2);
    assert.match(capturedUrl, /reference-profiles/);
    assert.match(capturedUrl, /tenantId=tenant-alpha/);
    assert.equal(capturedHeaders?.get("Authorization"), "Bearer access-token");
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("reference profiles rebuild route propagates session tenant and uses POST", async () => {
  const originalFetch = globalThis.fetch;
  let capturedUrl = "";
  let capturedHeaders: Headers | undefined;
  let capturedMethod = "";

  globalThis.fetch = async (input, init) => {
    capturedUrl = String(input);
    capturedHeaders = new Headers(init?.headers);
    capturedMethod = init?.method ?? "GET";
    return makeJsonResponse(200, {
      tenantId: "tenant-alpha",
      rebuiltHistoricalProfiles: 3,
      rebuiltRegionalProfiles: 2,
      totalProfilesAfterRebuild: 9
    });
  };

  try {
    const request = new NextRequest("http://localhost/api/intelligence/reference-profiles/rebuild", {
      method: "POST",
      headers: {
        cookie: sessionCookie()
      }
    });
    const response = await rebuildReferenceProfilesPost(request);
    const payload = (await response.json()) as { totalProfilesAfterRebuild: number };

    assert.equal(response.status, 200);
    assert.equal(payload.totalProfilesAfterRebuild, 9);
    assert.equal(capturedMethod, "POST");
    assert.match(capturedUrl, /reference-profiles\/rebuild/);
    assert.match(capturedUrl, /tenantId=tenant-alpha/);
    assert.equal(capturedHeaders?.get("Authorization"), "Bearer access-token");
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("capture gates route propagates session tenant and auth headers", async () => {
  const originalFetch = globalThis.fetch;
  let capturedUrl = "";
  let capturedHeaders: Headers | undefined;

  globalThis.fetch = async (input, init) => {
    capturedUrl = String(input);
    capturedHeaders = new Headers(init?.headers);
    return makeJsonResponse(200, {
      tenantId: "tenant-alpha",
      policyVersion: "capture-gates-v1",
      gates: [{ code: "DEVICE_GPS_ENABLED" }]
    });
  };

  try {
    const request = new NextRequest("http://localhost/api/intelligence/capture-gates", {
      headers: {
        cookie: sessionCookie()
      }
    });
    const response = await captureGatesGet(request);
    const payload = (await response.json()) as { policyVersion: string };

    assert.equal(response.status, 200);
    assert.equal(payload.policyVersion, "capture-gates-v1");
    assert.match(capturedUrl, /capture-gates/);
    assert.match(capturedUrl, /tenantId=tenant-alpha/);
    assert.equal(capturedHeaders?.get("Authorization"), "Bearer access-token");
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("normative matrix route propagates session tenant and auth headers", async () => {
  const originalFetch = globalThis.fetch;
  let capturedUrl = "";
  let capturedHeaders: Headers | undefined;

  globalThis.fetch = async (input, init) => {
    capturedUrl = String(input);
    capturedHeaders = new Headers(init?.headers);
    return makeJsonResponse(200, {
      tenantId: "tenant-alpha",
      matrixVersion: "normative-matrix-v1",
      profiles: [{ assetType: "Urbano", assetSubtype: "Apartamento", rules: [] }]
    });
  };

  try {
    const request = new NextRequest("http://localhost/api/intelligence/normative-matrix", {
      headers: {
        cookie: sessionCookie()
      }
    });
    const response = await normativeMatrixGet(request);
    const payload = (await response.json()) as { matrixVersion: string };

    assert.equal(response.status, 200);
    assert.equal(payload.matrixVersion, "normative-matrix-v1");
    assert.match(capturedUrl, /normative-matrix/);
    assert.match(capturedUrl, /tenantId=tenant-alpha/);
    assert.equal(capturedHeaders?.get("Authorization"), "Bearer access-token");
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("resolve preview route propagates case path and session tenant", async () => {
  const originalFetch = globalThis.fetch;
  let capturedUrl = "";

  globalThis.fetch = async (input) => {
    capturedUrl = String(input);
    return makeJsonResponse(200, {
      caseId: 18,
      caseNumber: "CASE-18",
      classification: { assetType: "Urbano", assetSubtype: "Apartamento", candidateAssetSubtypes: [] },
      captureGatePolicy: { tenantId: "tenant-alpha", policyVersion: "capture-gates-v1", gates: [] },
      normativeProfile: { assetType: "Urbano", assetSubtype: "Apartamento", rules: [] },
      previewNotes: []
    });
  };

  try {
    const request = new NextRequest("http://localhost/api/intelligence/cases/18/resolve-preview", {
      headers: {
        cookie: sessionCookie()
      }
    });
    const response = await resolvePreviewGet(request, {
      params: { caseId: "18" }
    });
    const payload = (await response.json()) as { caseId: number };

    assert.equal(response.status, 200);
    assert.equal(payload.caseId, 18);
    assert.match(capturedUrl, /cases\/18\/resolve-preview/);
    assert.match(capturedUrl, /tenantId=tenant-alpha/);
  } finally {
    globalThis.fetch = originalFetch;
  }
});
