import { NextRequest, NextResponse } from 'next/server';

export const dynamic = 'force-dynamic';

export async function GET(request: NextRequest) {
  try {
    const tenantId = request.headers.get('X-Tenant-Id') || 'tenant-default';
    const correlationId = request.headers.get('X-Correlation-Id') || `web-users-${Date.now()}`;

    const url = new URL('/api/users/pending', process.env.BACKEND_API_URL || 'http://localhost:8080');

    const response = await fetch(url.toString(), {
      method: 'GET',
      headers: {
        'X-Tenant-Id': tenantId,
        'X-Correlation-Id': correlationId,
        'Content-Type': 'application/json',
      },
    });

    if (!response.ok) {
      return NextResponse.json(
        { error: 'Failed to fetch pending users' },
        { status: response.status }
      );
    }

    const data = await response.json();
    return NextResponse.json(data);
  } catch (error) {
    console.error('Error fetching pending users:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
