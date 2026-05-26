import type { Config } from 'tailwindcss';
export default {
  content: ['./src/**/*.{js,ts,jsx,tsx,mdx}'],
  theme: {
    extend: {
      colors: {
        background: '#0A0A0F',
        surface: '#1A1A2E',
        secondarySurface: '#2A2A3E',
        accent: '#00FF88',
        secondaryAccent: '#8B5CF6',
        alert: '#FF3860',
        textPrimary: '#E8E8ED',
        textSecondary: '#8E8EA0',
      },
    },
  },
} satisfies Config;
