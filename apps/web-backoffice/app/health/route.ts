import { NextResponse } from "next/server";

export function GET() {
  return NextResponse.json({
    status: "ok",
    service: "web-backoffice",
    timestamp: new Date().toISOString()
  });
}
