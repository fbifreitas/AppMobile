import assert from "node:assert/strict";
import test from "node:test";

import { NextRequest } from "next/server";
import { POST as login } from "../app/api/auth/login/route";
import { GET as me } from "../app/api/auth/me/route";

function makeJsonResponse(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json"
    }
  });
}

test("auth login stores session cookie and me returns authenticated context", async () => {
  const originalFetch = globalThis.fetch;
  let backendCalls = 0;

  globalThis.fetch = async (input) => {
    backendCalls += 1;
    const url = String(input);
    if (url.endsWith("/auth/login")) {
      return makeJsonResponse(200, {
        accessToken: "access-token",
        refreshToken: "refresh-token",
        tokenType: "Bearer",
        expiresIn: 900
      });
    }

    return makeJsonResponse(200, {
      userId: 77,
      tenantId: "tenant-compass",
      email: "admin@compass.com",
      userStatus: "APPROVED",
      membershipRole: "TENANT_ADMIN",
      membershipStatus: "ACTIVE",
      permissions: ["tenant:*", "users:*"]
    });
  };

  try {
    const loginRequest = new NextRequest("http://localhost/api/auth/login", {
      method: "POST",
      body: JSON.stringify({
        tenantId: "tenant-compass",
        email: "admin@compass.com",
        password: "Compass@123"
      })
    });
    const loginResponse = await login(loginRequest);
    const loginPayload = (await loginResponse.json()) as { tenantId: string; membershipRole: string };
    const cookie = loginResponse.headers.get("set-cookie");

    assert.equal(loginResponse.status, 200);
    assert.equal(loginPayload.tenantId, "tenant-compass");
    assert.equal(loginPayload.membershipRole, "TENANT_ADMIN");
    assert.match(cookie || "", /backoffice_auth_session=/);
    assert.equal(backendCalls, 2);

    const meRequest = new NextRequest("http://localhost/api/auth/me", {
      headers: {
        cookie: cookie || ""
      }
    });
    const meResponse = await me(meRequest);
    const mePayload = (await meResponse.json()) as { email: string };

    assert.equal(meResponse.status, 200);
    assert.equal(mePayload.email, "admin@compass.com");
  } finally {
    globalThis.fetch = originalFetch;
  }
});
