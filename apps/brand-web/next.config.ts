import { NextConfig } from "next";

// GitHub Actions 빌드 환경 여부를 명시적으로 판단 (배포 안정화)
const isCI = process.env.GITHUB_ACTIONS === 'true';

const nextConfig: NextConfig = {
  // CI 환경(GitHub Pages 배포)이면 무조건 'export', 아니면 'standalone'(Docker/Coolify)
  output: isCI ? 'export' : 'standalone',
  
  // 정적 추출 시 명시적으로 'out' 디렉토리 사용 (Turbopack 인식 강화)
  distDir: isCI ? 'out' : '.next',
  
  // GitHub Pages 기본 주소 경로 설정 (레포지토리 이름이 Solve-for-X 인 경우 필수)
  basePath: isCI ? '/Solve-for-X' : '',
  
  // assetPrefix 추가: CSS/JS 로드 시 경로 앞에 레포지토리 이름을 붙여 404 방지
  assetPrefix: isCI ? '/Solve-for-X/' : '',

  images: {
    unoptimized: true, // GitHub Pages는 Next.js 자체 이미지 최적화 미지원하므로 필수 설정
  },
  
  // @ts-ignore
  allowedDevOrigins: ['192.168.45.61', 'localhost'], // 로컬/네트워크 HMR 허용
};

export default nextConfig;

