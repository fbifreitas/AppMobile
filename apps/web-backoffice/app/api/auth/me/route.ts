import { NextRequest, NextResponse } from "next/server";

import { readAuthSession, unauthorizedJson } from "../../../lib/auth_session";

export function GET(request: NextRequest) {
  const session = readAuthSession(request);
  if (!session) {
    return unauthorizedJson();
  }
  return NextResponse.json(session, { status: 200 });
}
