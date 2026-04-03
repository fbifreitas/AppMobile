import assert from "node:assert/strict";
import test from "node:test";

import { NextRequest } from "next/server";
import { POST as approvePost } from "../app/api/config/packages/approve/route";
import { POST as rollbackPost } from "../app/api/config/packages/rollback/route";

function makeJsonResponse(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json"
    }
  });
}

test("approve route retorna 400 quando tenantId esta ausente", async () => {
  const request = new NextRequest("http://localhost/api/config/packages/approve", {
    method: "POST",
    body: JSON.stringify({
      packageId: "cfg-001",
      actorId: "approver-web",
      actorRole: "tenant_admin"
    }),
    headers: {
      "Content-Type": "application/json"
    }
  });

  const response = await approvePost(request);
  const payload = (await response.json()) as { error: string };

  assert.equal(response.status, 400);
  assert.equal(payload.error, "Campos obrigatorios ausentes: packageId e tenantId");
});

test("approve route retorna 403 para role sem permissao", async () => {
  const request = new NextRequest("http://localhost/api/config/packages/approve", {
    method: "POST",
    body: JSON.stringify({
      packageId: "cfg-001",
      tenantId: "tenant-alpha",
      actorId: "operator-web",
      actorRole: "operator"
    }),
    headers: {
      "Content-Type": "application/json"
    }
  });

  const response = await approvePost(request);
  const payload = (await response.json()) as { error: string };

  assert.equal(response.status, 403);
  assert.equal(payload.error, "Perfil operator nao possui permissao para approve pacote de configuracao.");
});

test("approve route propaga 404 retornado pelo backend", async () => {
  const originalFetch = globalThis.fetch;

  globalThis.fetch = async () =>
    makeJsonResponse(404, {
      code: "CONFIG_PACKAGE_NOT_FOUND",
      message: "Pacote nao encontrado ou sem condicao de operacao"
    });

  try {
    const request = new NextRequest("http://localhost/api/config/packages/approve", {
      method: "POST",
      body: JSON.stringify({
        packageId: "cfg-001",
        tenantId: "tenant-beta",
        actorId: "approver-web",
        actorRole: "tenant_admin"
      }),
      headers: {
        "Content-Type": "application/json"
      }
    });

    const response = await approvePost(request);
    const payload = (await response.json()) as { code: string };

    assert.equal(response.status, 404);
    assert.equal(payload.code, "CONFIG_PACKAGE_NOT_FOUND");
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("rollback route propaga 404 retornado pelo backend", async () => {
  const originalFetch = globalThis.fetch;

  globalThis.fetch = async () =>
    makeJsonResponse(404, {
      code: "CONFIG_PACKAGE_NOT_FOUND",
      message: "Pacote nao encontrado ou sem condicao de operacao"
    });

  try {
    const request = new NextRequest("http://localhost/api/config/packages/rollback", {
      method: "POST",
      body: JSON.stringify({
        packageId: "cfg-001",
        tenantId: "tenant-beta",
        actorId: "operator-web",
        actorRole: "tenant_admin"
      }),
      headers: {
        "Content-Type": "application/json"
      }
    });

    const response = await rollbackPost(request);
    const payload = (await response.json()) as { code: string };

    assert.equal(response.status, 404);
    assert.equal(payload.code, "CONFIG_PACKAGE_NOT_FOUND");
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("approve route injeta X-Correlation-Id ao chamar backend", async () => {
  const originalFetch = globalThis.fetch;
  let capturedHeaders: Headers | undefined;

  globalThis.fetch = async (_input, init) => {
    capturedHeaders = new Headers(init?.headers);
    return makeJsonResponse(200, {
      message: "ok",
      result: {
        updated: {
          id: "cfg-001"
        }
      }
    });
  };

  try {
    const request = new NextRequest("http://localhost/api/config/packages/approve", {
      method: "POST",
      body: JSON.stringify({
        packageId: "cfg-001",
        tenantId: "tenant-alpha",
        actorId: "approver-web",
        actorRole: "tenant_admin"
      }),
      headers: {
        "Content-Type": "application/json"
      }
    });

    const response = await approvePost(request);

    assert.equal(response.status, 200);
    assert.match(capturedHeaders?.get("X-Correlation-Id") ?? "", /^cfg-/);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("rollback route injeta X-Correlation-Id ao chamar backend", async () => {
  const originalFetch = globalThis.fetch;
  let capturedHeaders: Headers | undefined;

  globalThis.fetch = async (_input, init) => {
    capturedHeaders = new Headers(init?.headers);
    return makeJsonResponse(200, {
      message: "ok",
      result: {
        updated: {
          id: "cfg-001"
        }
      }
    });
  };

  try {
    const request = new NextRequest("http://localhost/api/config/packages/rollback", {
      method: "POST",
      body: JSON.stringify({
        packageId: "cfg-001",
        tenantId: "tenant-alpha",
        actorId: "operator-web",
        actorRole: "tenant_admin"
      }),
      headers: {
        "Content-Type": "application/json"
      }
    });

    const response = await rollbackPost(request);

    assert.equal(response.status, 200);
    assert.match(capturedHeaders?.get("X-Correlation-Id") ?? "", /^cfg-/);
  } finally {
    globalThis.fetch = originalFetch;
  }
});
