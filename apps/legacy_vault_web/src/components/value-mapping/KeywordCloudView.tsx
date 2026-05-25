import { useValueMappingStore } from '../../stores/valueMappingStore'
import AppShell from '../layout/AppShell'

const C = {
  background: '#0A0A0F',
  surface: '#1A1A2E',
  surface2: '#2A2A3E',
  accent: '#00FF88',
  accent2: '#8B5CF6',
  text1: '#E8E8ED',
  text2: '#8E8EA0',
} as const

const categoryColors: Record<string, string> = {
  family: '#00FF88',
  career: '#8B5CF6',
  emotion: '#FFB347',
  challenge: '#FF3860',
  peace: '#4ECDC4',
  growth: '#45B7D1',
}

export default function KeywordCloudView() {
  const keywords = useValueMappingStore((s) => s.keywords)
  const maxFreq = Math.max(...keywords.map((k) => k.frequency))

  return (
    <AppShell>
      <div style={{ maxWidth: 800, margin: '0 auto' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 24 }}>
          <button
            onClick={() => (window.location.href = '/app/values')}
            style={{
              background: 'none',
              border: 'none',
              color: C.text2,
              cursor: 'pointer',
              fontSize: 20,
              padding: '4px 8px',
            }}
          >
            ←
          </button>
          <h1 style={{ fontSize: 20, fontWeight: 600, color: C.text1, margin: 0 }}>키워드 클라우드</h1>
        </div>

        <div
          style={{
            background: C.surface,
            borderRadius: 16,
            padding: 32,
            border: '1px solid rgba(255,255,255,0.05)',
            minHeight: 300,
            display: 'flex',
            flexWrap: 'wrap',
            alignItems: 'center',
            justifyContent: 'center',
            gap: 12,
          }}
        >
          {keywords.map((kw) => {
            const sizeScale = 0.6 + (kw.frequency / maxFreq) * 1.4
            const opacityScale = 0.5 + (kw.frequency / maxFreq) * 0.5
            const color = categoryColors[kw.category] || C.accent

            return (
              <span
                key={kw.id}
                style={{
                  fontSize: Math.round(14 * sizeScale),
                  fontWeight: Math.round(400 + (kw.frequency / maxFreq) * 300),
                  color,
                  opacity: opacityScale,
                  cursor: 'default',
                  padding: '4px 8px',
                  borderRadius: 6,
                  transition: 'transform 0.15s',
                  userSelect: 'none',
                }}
                onMouseEnter={(e) => {
                  ;(e.currentTarget as HTMLSpanElement).style.transform = 'scale(1.15)'
                }}
                onMouseLeave={(e) => {
                  ;(e.currentTarget as HTMLSpanElement).style.transform = ''
                }}
              >
                {kw.word}
              </span>
            )
          })}
        </div>

        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 10, marginTop: 16 }}>
          {Object.entries(categoryColors).map(([cat, color]) => (
            <div key={cat} style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
              <div style={{ width: 10, height: 10, borderRadius: '50%', background: color }} />
              <span style={{ fontSize: 12, color: C.text2 }}>
                {{
                  family: '가족',
                  career: '직업',
                  emotion: '감정',
                  challenge: '도전',
                  peace: '평화',
                  growth: '성장',
                }[cat]}
              </span>
            </div>
          ))}
        </div>
      </div>
    </AppShell>
  )
}
