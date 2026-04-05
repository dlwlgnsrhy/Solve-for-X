import { NextResponse } from 'next/server';

export const dynamic = 'force-static';

const isExport = process.env.NEXT_OUTPUT === 'export';

export async function GET() {
  if (isExport) {
    return NextResponse.json({ 
      status: 'OFFLINE', 
      message: 'Core server check is unavailable in Static Export mode.' 
    });
  }

  try {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 5000);

    const startTime = Date.now();
    // Proxy request to the Legacy Core Spring Boot server
    const res = await fetch('http://localhost:8080/api/v1/health', {
      signal: controller.signal,
      cache: 'no-store', // ensures we do not cache health checks
    });

    
    clearTimeout(timeoutId);
    
    const latency = Date.now() - startTime;

    if (!res.ok) {
      return NextResponse.json(
        { status: 'OFFLINE', message: 'Core server responded with error' },
        { status: 502 }
      );
    }

    const data = await res.json();
    return NextResponse.json({ ...data, latency });
    
  } catch (error) {
    return NextResponse.json(
      { status: 'OFFLINE', message: 'Core server unreachable', error: String(error) },
      { status: 503 }
    );
  }
}

