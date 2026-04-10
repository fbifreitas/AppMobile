import { NextRequest, NextResponse } from "next/server";

import { isAuthSession, loginWithBackend, writeAuthSession } from "../../../lib/auth_session";

export async function POST(request: NextRequest) {
  const payload = await request.json();
  const result = await loginWithBackend(payload);

  if (result.status >= 400 || !isAuthSession(result.payload)) {
    return NextResponse.json(result.payload, { status: result.status });
  }

  const response = NextResponse.json(result.payload, { status: 200 });
  writeAuthSession(response, result.payload);
  return response;
}
