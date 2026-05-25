import { NextResponse } from 'next/server';
import fs from 'fs';
import path from 'path';

function cleanText(text: string): string {
  return text
    .replace(/\*\*/g, '') // remove bold markers
    .replace(/`/g, '') // remove backticks
    .replace(/\[(.*?)\]\(.*?\)/g, '$1'); // simplify links to plain text
}

export async function GET() {
  try {
    const goalPath = '/Users/apple/development/soluni/Solve-for-X/docs/plans/goal.md';
    if (!fs.existsSync(goalPath)) {
      return NextResponse.json({
        status: 'ERROR',
        error: 'goal.md file not found at ' + goalPath
      }, { status: 404 });
    }

    const content = fs.readFileSync(goalPath, 'utf-8');
    const sections = content.split('### Phase');
    const phases: any[] = [];

    for (let i = 1; i < sections.length; i++) {
      const section = sections[i];
      const lines = section.split('\n').map(l => l.trim()).filter(l => l.length > 0);
      if (lines.length === 0) continue;

      const headerLine = lines[0];
      let phaseNum = i;
      let phaseTitle = '';
      let status = '';
      
      const headerMatch = headerLine.match(/^(\d+):\s*(.*?)\s*-\s*\[(.*?)\]/);
      if (headerMatch) {
        phaseNum = parseInt(headerMatch[1]);
        phaseTitle = headerMatch[2];
        status = headerMatch[3];
      } else {
        phaseTitle = headerLine;
      }

      let objective = '';
      const bullets: string[] = [];

      for (let j = 1; j < lines.length; j++) {
        const line = lines[j];
        if (line.startsWith('**목표:')) {
          objective = line.replace(/^\*\*목표:\s*/, '').replace(/\*\*$/, '');
        } else if (line.includes('Focus:**') || line.includes('Focus:')) {
          continue;
        } else if (line.startsWith('*') || line.startsWith('-')) {
          const bulletText = line.replace(/^[\*\-\s]+/, '').trim();
          if (bulletText) {
            bullets.push(cleanText(bulletText));
          }
        } else if (line.startsWith('###') || line.startsWith('---')) {
          continue;
        } else {
          const cleanLine = line.replace(/^[\*\-\s`]+/, '').replace(/`+$/, '').trim();
          if (cleanLine && cleanLine.length > 5) {
            bullets.push(cleanText(cleanLine));
          }
        }
      }

      phases.push({
        phaseNum,
        phaseTitle: `Phase ${phaseNum}: ${phaseTitle}`,
        status,
        objective,
        bullets: bullets.slice(0, 3)
      });
    }

    return NextResponse.json({
      status: 'SUCCESS',
      phases
    });
  } catch (error: any) {
    return NextResponse.json({
      status: 'ERROR',
      error: error.message || String(error)
    }, { status: 500 });
  }
}
