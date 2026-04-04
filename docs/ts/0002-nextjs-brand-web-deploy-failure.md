# 2. Next.js Brand Web GitHub Pages 배포 실패 해결

Date: 2026-04-04

## Problem
- [dlwlgnsrhy/Solve-for-X] 브랜드 웹 배포 워크플로(`Deploy Next.js Brand Web to GitHub Pages`)가 빌드 단계(21초 내외)에서 실패함.
- GitHub Pages 배포를 위한 `out` 디렉토리가 생성되지 않아 `Upload artifact` 단계에서 파일 없음 오류 발생.

## Cause
- **Build Output mismatch:** Next.js가 Docker/Coolify용 `standalone`으로 설정되어 있어 정적 파일(`export`)이 생성되지 않음.
- **Dynamic API route:** `src/app/api/sre/health`가 외부 통신을 시도하는 동적 라우트였으며, `next export` 시 빌드 검증을 통과하지 못함.
- **Base Path absence:** GitHub Pages의 기본 주소(`...github.io/Solve-for-X/`)에 맞는 `basePath` 설정이 누락됨.

## Solution
1. **Conditional next.config.ts:** `NEXT_OUTPUT` 환경 변수에 따라 `output: 'export'`, `basePath: '/Solve-for-X'`, `images.unoptimized: true`가 적용되도록 수정.
2. **Static-ready API Route:** 정적 빌드 시 fetch 시도를 방지하기 위해 `isExport` 조건문을 추가하고 더미 응답을 반환하도록 수정.
3. **Workflow Patching Strategy:** `sed`를 사용하여 빌드 직전에 API 라우트의 `export const dynamic = 'force-static'` 주석을 해제하는 단계를 GitHub Actions 워크플로에 삽입 (Next.js 16/Turbopack 대응).

## Note
- 현재 설정으로 Docker 배포(standalone)와 GitHub Pages 배포(static export)를 하나의 소스 코드로 동시 지원할 수 있습니다.
- 향후 배포 시 `NEXT_OUTPUT=export` 환경 변수 여부에 따라 빌드 아티팩트의 성격이 결정됩니다.
