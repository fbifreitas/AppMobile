import { NextRequest, NextResponse } from "next/server";

import { clearAuthSession, logoutWithBackend, readAuthSession } from "../../../lib/auth_session";

export async function POST(request: NextRequest) {
  const session = readAuthSession(request);
  const response = NextResponse.json({ ok: true }, { status: 200 });

  if (session) {
    await logoutWithBackend(session);
  }

  clearAuthSession(response);
  return response;
}
