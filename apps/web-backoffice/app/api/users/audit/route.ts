import { NextRequest, NextResponse } from 'next/server';

export const dynamic = 'force-dynamic';

const BACKEND_BASE_URL = process.env.BACKEND_API_URL || 'http://localhost:8080';

export async function GET(request: NextRequest) {
  try {
    const url = new URL('/api/users/audit', BACKEND_BASE_URL);
    const userId = request.nextUrl.searchParams.get('userId');
    if (userId) {
      url.searchParams.set('userId', userId);
    }

    const response = await fetch(url.toString(), {
      method: 'GET',
      headers: {
        'X-Tenant-Id': request.headers.get('X-Tenant-Id') || 'tenant-default',
        'X-Correlation-Id': request.headers.get('X-Correlation-Id') || `web-users-audit-${Date.now()}`,
        'X-Actor-Id': request.headers.get('X-Actor-Id') || 'backoffice-auditor',
        'Content-Type': 'application/json',
      },
    });

    const body = await response.json();
    if (!response.ok) {
      return NextResponse.json(body, { status: response.status });
    }

    return NextResponse.json(body, { status: 200 });
  } catch (error) {
    console.error('Error fetching user audit trail:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}