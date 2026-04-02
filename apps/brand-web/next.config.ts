import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // output: 'export', // 비활성화: API Route(/api/sre/health)를 사용하기 위함
  // @ts-ignore
  allowedDevOrigins: ['192.168.45.61', 'localhost'], // 로컬/네트워크(모바일 등) HMR 허용
};

export default nextConfig;
