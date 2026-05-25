import { NextResponse } from 'next/server';
import fs from 'fs';
import path from 'path';

export async function GET(
  request: Request,
  { params }: { params: Promise<{ filename: string }> }
) {
  try {
    const { filename } = await params;
    
    // Secure check to prevent path traversal
    if (filename.includes('..') || filename.includes('/') || filename.includes('\\')) {
      return new Response('Access Denied', { status: 403 });
    }

    const imagePath = path.join('/Users/apple/development/soluni/Solve-for-X/docs/images', filename);
    
    if (!fs.existsSync(imagePath)) {
      return new Response('Not Found', { status: 404 });
    }

    const fileBuffer = fs.readFileSync(imagePath);
    return new Response(fileBuffer, {
      headers: {
        'Content-Type': 'image/png',
        'Cache-Control': 'public, max-age=60',
      },
    });
  } catch (error: any) {
    return new Response('Internal Server Error: ' + error.message, { status: 500 });
  }
}
