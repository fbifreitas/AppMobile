import { NextRequest, NextResponse } from "next/server";

import { AUTH_SESSION_COOKIE } from "./app/lib/auth_session";

function isProtectedPath(pathname: string): boolean {
  return pathname.startsWith("/backoffice/platform") || pathname.startsWith("/backoffice/users");
}

export function middleware(request: NextRequest) {
  if (!isProtectedPath(request.nextUrl.pathname)) {
    return NextResponse.next();
  }

  if (request.cookies.get(AUTH_SESSION_COOKIE)?.value) {
    return NextResponse.next();
  }

  const loginUrl = new URL("/login", request.url);
  loginUrl.searchParams.set("next", request.nextUrl.pathname);
  return NextResponse.redirect(loginUrl);
}

export const config = {
  matcher: ["/backoffice/:path*"]
};
