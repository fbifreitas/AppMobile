import { NextRequest, NextResponse } from 'next/server';

export const dynamic = 'force-dynamic';

const BACKEND_BASE_URL = process.env.BACKEND_API_URL || 'http://localhost:8080';

function buildHeaders(request: NextRequest): HeadersInit {
  return {
    'X-Tenant-Id': request.headers.get('X-Tenant-Id') || 'tenant-default',
    'X-Correlation-Id': request.headers.get('X-Correlation-Id') || `web-user-onboarding-${Date.now()}`,
    'X-Actor-Id': request.headers.get('X-Actor-Id') || 'backoffice-operator',
    'Content-Type': 'application/json',
  };
}

export async function GET(request: NextRequest) {
  try {
    const url = new URL('/api/users/onboarding-statuses', BACKEND_BASE_URL);
    const response = await fetch(url.toString(), {
      method: 'GET',
      headers: buildHeaders(request),
    });

    const body = await response.json();
    if (!response.ok) {
      return NextResponse.json(body, { status: response.status });
    }

    return NextResponse.json(body, { status: 200 });
  } catch (error) {
    console.error('Error fetching onboarding statuses:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
