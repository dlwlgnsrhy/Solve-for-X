import { NextResponse } from 'next/server';
import { execSync } from 'child_process';
import fs from 'fs';
import path from 'path';

// Define local brand-tokens dictionary matching app.py for precise color preset resolution
const BRAND_TOKENS: Record<string, { p_c: string; s_c: string; bg_c: string; card_c: string }> = {
  "미니멀 모던 (Neutral Modern)": { p_c: "#3b82f6", s_c: "#10b981", bg_c: "#f3f4f6", card_c: "#ffffff" },
  "포근한 파스텔 (Cozy Warm Pastel)": { p_c: "#a78bfa", s_c: "#f472b6", bg_c: "#f9fafb", card_c: "#ffffff" },
  "네온 사이버펑크 (Cyberpunk Neon)": { p_c: "#00f0ff", s_c: "#ff007f", bg_c: "#090514", card_c: "#120b24" },
  "시크 다크 프로페셔널 (Sleek Dark Professional)": { p_c: "#6366f1", s_c: "#ec4899", bg_c: "#0b0f19", card_c: "#111827" },
  "에메랄드 가든 (Emerald Garden)": { p_c: "#34d399", s_c: "#047857", bg_c: "#f0fdf4", card_c: "#ffffff" },
  "노을빛 선셋 (Sunset Glow)": { p_c: "#f87171", s_c: "#fbbf24", bg_c: "#fffbeb", card_c: "#ffffff" },
  "클래식 로열 (Royal Velvet)": { p_c: "#8b5cf6", s_c: "#f59e0b", bg_c: "#0f0a1c", card_c: "#16102b" },
  "도쿄 나이트 (Tokyo Night)": { p_c: "#7aa2f7", s_c: "#ff007f", bg_c: "#1a1b26", card_c: "#24283b" },
  "nordic": { p_c: "#88c0d0", s_c: "#81a1c1", bg_c: "#d8dee9", card_c: "#e5e9f0" },
  "dracula": { p_c: "#bd93f9", s_c: "#50fa7b", bg_c: "#282a36", card_c: "#44475a" }
};

export async function POST(req: Request) {
  const logs: string[] = [];
  let tempSpecPath = '';

  try {
    const body = await req.json();
    const { appName, designSystem, fidelity, targetPlatform, prompt } = body;

    if (!appName || !prompt) {
      return NextResponse.json({
        status: 'ERROR',
        error: 'appName and prompt are required'
      }, { status: 400 });
    }

    logs.push(`🚀 Brand Web API Forge: Spawning AI Design Factory for App [${appName}]...`);

    // Derive package name and appId
    const cleanName = appName.replace(/[^a-zA-Z0-9]/g, '').toLowerCase();
    const appId = `com_${cleanName}_privacy`;
    const packageName = `com.${cleanName}.privacy`;

    // Map design system color tokens
    const preset = BRAND_TOKENS[designSystem] || BRAND_TOKENS["포근한 파스텔 (Cozy Warm Pastel)"];
    let p_c = preset.p_c;
    let s_c = preset.s_c;
    let bg_c = preset.bg_c;
    let card_c = preset.card_c;

    if (fidelity && fidelity.includes("와이어프레임")) {
      p_c = "#9ca3af";
      s_c = "#4b5563";
      bg_c = "#f9fafb";
      card_c = "#ffffff";
    }

    // Compose parsed spec JSON
    const parsedSpec = {
      app_name: appName,
      package_name: packageName,
      design_system: designSystem,
      target_platform: targetPlatform || "Responsive Web",
      fidelity: fidelity || "High fidelity",
      prompt: prompt,
      primary_color: p_c,
      secondary_color: s_c,
      background_color: bg_c,
      card_color: card_c,
      hero_title: appName,
      hero_subtitle: prompt,
      dynamic_items: [
        { title: "Encrypted Vault", description: "Zero-knowledge hardware lockbox.", icon: "security" },
        { title: "Mindful Journal", description: "Offline secure narrative logging.", icon: "favorite" },
        { title: "Sentinel Guard", description: "Biometric monitoring and threat prevention.", icon: "shield" }
      ]
    };

    // Write temp spec to /tmp
    tempSpecPath = path.join('/tmp', `temp_spec_${appId}.json`);
    fs.writeFileSync(tempSpecPath, JSON.stringify(parsedSpec, null, 2), 'utf-8');
    logs.push(`📝 SPEC GENERATED: Written to ${tempSpecPath}`);

    // Define all absolute directories
    const engineScript = '/Users/apple/development/soluni/Solve-for-X/architecture/app-factory-engine/engine.py';
    const templateDir = '/Users/apple/development/soluni/Solve-for-X/architecture/base_flutter_app';
    const targetBuildPath = `/Users/apple/development/soluni/Solve-for-X/architecture/builds/${appId}`;

    // Execute engine.py to compile Dart views
    logs.push(`🤖 GEN ENGINE: Executing Python App Factory Engine to synthesize codebase...`);
    const engineCmd = `python3 ${engineScript} --out ${targetBuildPath} --template ${templateDir} --spec ${tempSpecPath} --use-ai`;
    
    try {
      const engineOut = execSync(engineCmd, {
        env: { ...process.env, PATH: `${process.env.PATH}:/Users/apple/development/flutter/bin` },
        timeout: 90000, // 90 seconds timeout
        encoding: 'utf-8'
      });
      logs.push(`✨ ENGINE OUTPUT:`);
      engineOut.split('\n').forEach(line => {
        if (line.trim()) logs.push(`  ${line.trim()}`);
      });
    } catch (engineErr: any) {
      logs.push(`❌ ENGINE ERROR: Python script failed or timed out: ${engineErr.message}`);
      if (engineErr.stdout) logs.push(`Stdout: ${engineErr.stdout}`);
      if (engineErr.stderr) logs.push(`Stderr: ${engineErr.stderr}`);
      throw new Error(`Engine synthesis failed: ${engineErr.message}`);
    }

    // Execute flutter build web
    logs.push(`⚡ COMPILER: Running 'flutter build web --release' inside ${targetBuildPath}...`);
    try {
      const buildOut = execSync(`flutter build web --release`, {
        cwd: targetBuildPath,
        env: { ...process.env, PATH: `${process.env.PATH}:/Users/apple/development/flutter/bin` },
        timeout: 120000, // 2 minutes timeout
        encoding: 'utf-8'
      });
      logs.push(`✨ FLUTTER COMPILE SUCCESS!`);
      buildOut.split('\n').forEach(line => {
        if (line.trim()) logs.push(`  ${line.trim()}`);
      });
    } catch (buildErr: any) {
      logs.push(`❌ COMPILE ERROR: Flutter compilation failed: ${buildErr.message}`);
      if (buildErr.stdout) logs.push(`Stdout: ${buildErr.stdout}`);
      if (buildErr.stderr) logs.push(`Stderr: ${buildErr.stderr}`);
      throw new Error(`Flutter compilation failed: ${buildErr.message}`);
    }

    // Publish build results
    logs.push(`📂 PUBLISHER: Distributing compiled web assets to brand portals...`);
    const webBuildDir = path.join(targetBuildPath, 'build', 'web');
    if (!fs.existsSync(webBuildDir)) {
      throw new Error("No compiled web build directory found.");
    }

    const publishTargets = [
      {
        name: "Sandbox Portal",
        dir: `/Users/apple/development/soluni/Solve-for-X/architecture/brand-web/apps/${appId}`,
        registry: `/Users/apple/development/soluni/Solve-for-X/architecture/brand-web/assets/apps_registry.json`,
        baseHref: `/apps/${appId}/`
      },
      {
        name: "Production Next.js Portal",
        dir: `/Users/apple/development/soluni/Solve-for-X/apps/brand-web/public/apps/${appId}`,
        registry: `/Users/apple/development/soluni/Solve-for-X/apps/brand-web/public/assets/apps_registry.json`,
        baseHref: `/Solve-for-X/apps/${appId}/`
      }
    ];

    for (const target of publishTargets) {
      // Clear and copy folder
      if (fs.existsSync(target.dir)) {
        fs.rmSync(target.dir, { recursive: true, force: true });
      }
      fs.mkdirSync(target.dir, { recursive: true });
      
      // Copy files recursively
      execSync(`cp -r ${webBuildDir}/* ${target.dir}/`);

      // Patch base href in index.html
      const indexHtml = path.join(target.dir, 'index.html');
      if (fs.existsSync(indexHtml)) {
        let content = fs.readFileSync(indexHtml, 'utf-8');
        content = content.replace(/<base\s+href="[^"]*"/, `<base href="${target.baseHref}"`);
        fs.writeFileSync(indexHtml, content, 'utf-8');
      }

      // Sync registry file
      let registryData = [];
      if (fs.existsSync(target.registry)) {
        try {
          registryData = JSON.parse(fs.readFileSync(target.registry, 'utf-8'));
        } catch {
          registryData = [];
        }
      }

      // Check for existing entry
      const existingIdx = registryData.findIndex((item: any) => item.app_id === appId);
      const appEntry = {
        app_id: appId,
        app_name: appName,
        design_system: p_c,
        path: `apps/${appId}/`,
        custom_pages: [
          "lib/config/app_config.dart",
          "lib/main.dart"
        ]
      };

      if (existingIdx >= 0) {
        registryData[existingIdx] = appEntry;
      } else {
        registryData.push(appEntry);
      }

      fs.writeFileSync(target.registry, JSON.stringify(registryData, null, 2), 'utf-8');
      logs.push(`✅ Successfully published assets to ${target.name}`);
    }

    logs.push(`🎉 AI APP FORGE COMPLETED! Newly minted micro app [${appName}] is now active and ready!`);
    return NextResponse.json({
      status: 'SUCCESS',
      appId,
      appName,
      logs
    });

  } catch (error: any) {
    logs.push(`❌ FORGE FATAL EXCEPTION: ${error.message}`);
    return NextResponse.json({
      status: 'ERROR',
      logs,
      error: error.message || String(error)
    }, { status: 500 });
  } finally {
    if (tempSpecPath && fs.existsSync(tempSpecPath)) {
      try {
        fs.unlinkSync(tempSpecPath);
      } catch {}
    }
  }
}
