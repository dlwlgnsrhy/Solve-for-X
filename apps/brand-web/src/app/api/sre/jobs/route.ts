import { NextResponse } from 'next/server';
import { execSync } from 'child_process';

const QUERY_SCRIPT_PATH = '/Users/apple/development/soluni/Solve-for-X/scripts/unicorn_factory/query_jobs.py';

export async function GET() {
  try {
    const output = execSync(`python3 ${QUERY_SCRIPT_PATH}`, {
      env: { ...process.env },
      timeout: 10000,
      encoding: 'utf-8'
    });
    
    const jobs = JSON.parse(output);
    return NextResponse.json({
      status: 'SUCCESS',
      jobs
    });
  } catch (error: any) {
    return NextResponse.json({
      status: 'ERROR',
      error: error.message || String(error)
    }, { status: 500 });
  }
}

export async function POST(req: Request) {
  try {
    const body = await req.json();
    const { commandText, targetApp } = body;

    if (!commandText) {
      return NextResponse.json({
        status: 'ERROR',
        error: 'commandText is required'
      }, { status: 400 });
    }

    const app = targetApp || 'sfx_memento_mori';
    
    // Sanitize commandText to avoid shell injection issues
    const sanitizedCommand = commandText.replace(/"/g, '\\"');
    
    const cmd = `python3 ${QUERY_SCRIPT_PATH} --register "${sanitizedCommand}" "${app}"`;
    
    const output = execSync(cmd, {
      env: { ...process.env },
      timeout: 15000,
      encoding: 'utf-8'
    });

    const res = JSON.parse(output);
    return NextResponse.json(res);
  } catch (error: any) {
    return NextResponse.json({
      status: 'ERROR',
      error: error.message || String(error)
    }, { status: 500 });
  }
}
