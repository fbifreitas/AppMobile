import { NextRequest, NextResponse } from 'next/server';

export const dynamic = 'force-dynamic';

const BACKEND_BASE_URL = process.env.BACKEND_API_URL || 'http://localhost:8080';

export async function POST(request: NextRequest) {
  try {
    const payload = await request.json();
    const url = new URL('/api/users/import', BACKEND_BASE_URL);

    const response = await fetch(url.toString(), {
      method: 'POST',
      headers: {
        'X-Tenant-Id': request.headers.get('X-Tenant-Id') || 'tenant-default',
        'X-Correlation-Id': request.headers.get('X-Correlation-Id') || `web-users-import-${Date.now()}`,
        'X-Actor-Id': request.headers.get('X-Actor-Id') || 'backoffice-operator',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(payload),
    });

    const body = await response.json();
    if (!response.ok) {
      return NextResponse.json(body, { status: response.status });
    }

    return NextResponse.json(body, { status: 200 });
  } catch (error) {
    console.error('Error importing users:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
