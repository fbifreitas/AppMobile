import { NextRequest, NextResponse } from 'next/server';
import { buildAuthenticatedHeaders, readAuthSession, unauthorizedJson } from '../../lib/auth_session';

export const dynamic = 'force-dynamic';

const BACKEND_BASE_URL = process.env.BACKEND_API_URL || 'http://localhost:8080';

export async function GET(request: NextRequest) {
  const session = readAuthSession(request);
  if (!session) {
    return unauthorizedJson();
  }

  try {
    const url = new URL('/api/users', BACKEND_BASE_URL);
    const status = request.nextUrl.searchParams.get('status');
    if (status) {
      url.searchParams.set('status', status);
    }

    const response = await fetch(url.toString(), {
      method: 'GET',
      headers: buildAuthenticatedHeaders(session, 'web-users-list'),
    });

    const body = await response.json();
    if (!response.ok) {
      return NextResponse.json(body, { status: response.status });
    }

    return NextResponse.json(body, { status: 200 });
  } catch (error) {
    console.error('Error fetching users:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}

export async function POST(request: NextRequest) {
  const session = readAuthSession(request);
  if (!session) {
    return unauthorizedJson();
  }

  try {
    const payload = await request.json();
    const url = new URL('/api/users', BACKEND_BASE_URL);

    const response = await fetch(url.toString(), {
      method: 'POST',
      headers: buildAuthenticatedHeaders(session, 'web-users-create'),
      body: JSON.stringify(payload),
    });

    const body = await response.json();
    if (!response.ok) {
      return NextResponse.json(body, { status: response.status });
    }

    return NextResponse.json(body, { status: response.status });
  } catch (error) {
    console.error('Error creating user:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
