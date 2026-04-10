import assert from "node:assert/strict";
import test from "node:test";

import { NextRequest } from "next/server";
import { middleware } from "../middleware";

test("middleware redirects unauthenticated backoffice pages to login", () => {
  const request = new NextRequest("http://localhost/backoffice/config");
  const response = middleware(request);

  assert.equal(response.status, 307);
  assert.equal(response.headers.get("location"), "http://localhost/login?next=%2Fbackoffice%2Fconfig");
});

test("middleware allows authenticated backoffice pages", () => {
  const request = new NextRequest("http://localhost/backoffice/config", {
    headers: {
      cookie: "backoffice_auth_session=session-value"
    }
  });
  const response = middleware(request);

  assert.equal(response.status, 200);
  assert.equal(response.headers.get("location"), null);
});
