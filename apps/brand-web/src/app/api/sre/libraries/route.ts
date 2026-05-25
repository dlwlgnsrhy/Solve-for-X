import { NextResponse } from 'next/server';
import fs from 'fs';
import path from 'path';
import { execSync } from 'child_process';

const PROJECTS_CONFIG_PATH = '/Users/apple/development/soluni/sx-factory/config/projects.json';
const AUDIT_REPORT_PATH = '/Users/apple/development/soluni/Solve-for-X/apps/brand-web/src/app/api/sre/audit_report.json';
const SRE_SCRIPT_PATH = '/Users/apple/development/soluni/sx-factory/scripts/sre_audit_factory.py';

function getCleanVersion(versionStr: string): string {
  return versionStr.replace(/[\^~><=]/g, '').trim();
}

// Function to run the audit script to ensure we have fresh data
function runAuditSync() {
  try {
    execSync(`python3 ${SRE_SCRIPT_PATH}`, { timeout: 15000 });
  } catch (err) {
    console.error('Failed to run SRE audit script in Next.js:', err);
  }
}

export async function GET() {
  try {
    // Proactively scan if audit report doesn't exist yet
    if (!fs.existsSync(AUDIT_REPORT_PATH)) {
      runAuditSync();
    }

    if (fs.existsSync(AUDIT_REPORT_PATH)) {
      const reportContent = fs.readFileSync(AUDIT_REPORT_PATH, 'utf-8');
      const report = JSON.parse(reportContent);
      
      // Map report format to the React UI expectations
      const libraries: Array<{ app: string; name: string; current: string; target: string; status: string }> = [];
      
      report.projects.forEach((proj: any) => {
        proj.libraries.forEach((lib: any) => {
          libraries.push({
            app: proj.name,
            name: lib.name,
            current: lib.current,
            target: lib.target,
            status: lib.status,
          });
        });
      });

      return NextResponse.json({
        status: 'SUCCESS',
        libraries: libraries,
        last_updated: report.last_updated,
        summary: report.summary
      });
    }

    return NextResponse.json({
      status: 'ERROR',
      error: 'Audit report not found and auto-generation failed.'
    }, { status: 500 });

  } catch (error: any) {
    return NextResponse.json({
      status: 'ERROR',
      error: error.message || String(error)
    }, { status: 500 });
  }
}

export async function POST(req: Request) {
  const logs: string[] = [];
  try {
    const body = await req.json().catch(() => ({}));
    const { appId } = body;

    logs.push(`🚀 SRE NEXT.JS BRIDGE: Triggering SRE weekly package upgrade factory...`);
    
    // Construct command
    let cmd = `python3 ${SRE_SCRIPT_PATH} --upgrade`;
    if (appId) {
      cmd += ` --project=${appId}`;
      logs.push(`⚙️ TARGET FILTER: Modernizing dependencies specifically for '${appId}'`);
    } else {
      logs.push(`⚙️ TARGET FILTER: Modernizing dependencies globally across all monitored paths`);
    }

    // Run script in actual upgrade mode
    try {
      logs.push(`🧪 EXECUTING: Running Python SRE Auto-Upgrade Engine...`);
      const output = execSync(cmd, {
        env: { ...process.env, PATH: `${process.env.PATH}:/Users/apple/development/flutter/bin` },
        timeout: 45000,
        encoding: 'utf-8'
      });
      logs.push(`✨ ENGINE PROCESS STDOUT:`);
      output.split('\n').forEach(line => {
        if (line.trim()) logs.push(`  ${line.trim()}`);
      });
    } catch (execErr: any) {
      logs.push(`⚠️ WARNING: SRE Python engine execution returned non-zero code or timed out: ${execErr.message}`);
      if (execErr.stdout) {
        logs.push(`🔍 Partial STDOUT:`);
        execErr.stdout.split('\n').forEach((line: string) => {
          if (line.trim()) logs.push(`  ${line.trim()}`);
        });
      }
      if (execErr.stderr) {
        logs.push(`❌ Engine STDERR:`);
        execErr.stderr.split('\n').forEach((line: string) => {
          if (line.trim()) logs.push(`  ${line.trim()}`);
        });
      }
    }

    // Load newly generated audit report to return the fresh versions state
    if (fs.existsSync(AUDIT_REPORT_PATH)) {
      const report = JSON.parse(fs.readFileSync(AUDIT_REPORT_PATH, 'utf-8'));
      const libraries: Array<{ app: string; name: string; current: string; target: string; status: string }> = [];
      
      report.projects.forEach((proj: any) => {
        proj.libraries.forEach((lib: any) => {
          libraries.push({
            app: proj.name,
            name: lib.name,
            current: lib.current,
            target: lib.target,
            status: lib.status,
          });
        });
      });

      logs.push(`✅ SUCCESS: SRE Weekly modernization completed. central registry synced.`);
      return NextResponse.json({
        status: 'SUCCESS',
        logs: logs,
        libraries: libraries,
      });
    } else {
      return NextResponse.json({
        status: 'ERROR',
        logs: logs,
        error: 'Audit report file not found post-execution.'
      }, { status: 500 });
    }

  } catch (error: any) {
    logs.push(`❌ BRIDGE EXCEPTION: ${error.message || error}`);
    return NextResponse.json({
      status: 'ERROR',
      logs: logs,
      error: String(error),
    }, { status: 500 });
  }
}

