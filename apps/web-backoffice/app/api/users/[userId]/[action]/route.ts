import { NextRequest, NextResponse } from 'next/server';

export const dynamic = 'force-dynamic';

export async function POST(
  request: NextRequest,
  { params }: { params: { userId: string; action: string } }
) {
  try {
    const tenantId = request.headers.get('X-Tenant-Id') || 'tenant-default';
    const correlationId = request.headers.get('X-Correlation-Id') || `web-users-${Date.now()}`;
    const { userId, action } = params;

    const endpoint =
      action === 'approve'
        ? `/api/users/${userId}/approve`
        : `/api/users/${userId}/reject`;

    const url = new URL(endpoint, process.env.BACKEND_API_URL || 'http://localhost:8080');
    const body = await request.json();

    const response = await fetch(url.toString(), {
      method: 'POST',
      headers: {
        'X-Tenant-Id': tenantId,
        'X-Correlation-Id': correlationId,
        'X-Actor-Id': request.headers.get('X-Actor-Id') || 'backoffice-approver',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body),
    });

    if (!response.ok) {
      const error = await response.json();
      return NextResponse.json(error, { status: response.status });
    }

    const data = await response.json();
    return NextResponse.json(data);
  } catch (error) {
    console.error('Error processing user approval:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
