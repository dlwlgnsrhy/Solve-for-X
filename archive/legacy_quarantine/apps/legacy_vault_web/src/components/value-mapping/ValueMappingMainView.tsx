import AppShell from '../layout/AppShell'
import { useValueMappingStore } from '../../stores/valueMappingStore'

const C = {
  background: '#0A0A0F',
  surface: '#1A1A2E',
  surface2: '#2A2A3E',
  accent: '#00FF88',
  accent2: '#8B5CF6',
  text1: '#E8E8ED',
  text2: '#8E8EA0',
} as const

export default function ValueMappingMainView() {
  const { keywords, entries } = useValueMappingStore()

  const categoryCounts = {
    family: keywords.filter((k) => k.category === 'family').length,
    career: keywords.filter((k) => k.category === 'career').length,
    emotion: keywords.filter((k) => k.category === 'emotion').length,
    challenge: keywords.filter((k) => k.category === 'challenge').length,
    peace: keywords.filter((k) => k.category === 'peace').length,
    growth: keywords.filter((k) => k.category === 'growth').length,
  }

  return (
    <AppShell>
      <div style={{ maxWidth: 960, margin: '0 auto' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
          <h1 style={{ fontSize: 24, fontWeight: 600, color: C.accent }}>🧠 Value Mapping</h1>
          <span style={{ fontSize: 13, color: C.text2 }}>
            {keywords.length}개 키워드 · {entries.length}개 기록
          </span>
        </div>

        <div
          style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fill, minmax(200px, 1fr))',
            gap: 12,
            marginBottom: 24,
          }}
        >
          {[
            { href: '/app/values/keywords', icon: '🏷', title: '키워드 클라우드', count: keywords.length },
            { href: '/app/values/timeline', icon: '📅', title: '타임라인', count: entries.length },
            { href: '/app/values/insights', icon: '💡', title: '인사이트', count: 6 },
            { href: '/app/values/entries', icon: '📝', title: '기록 보기', count: entries.length },
          ].map((card) => (
            <a
              key={card.title}
              href={card.href}
              style={{
                textDecoration: 'none',
                background: C.surface,
                borderRadius: 14,
                padding: 20,
                border: '1px solid rgba(255,255,255,0.05)',
                transition: 'transform 0.15s ease, border-color 0.15s ease',
              }}
              onMouseEnter={(e) => {
                ;(e.currentTarget as HTMLAnchorElement).style.transform = 'translateY(-2px)'
                ;(e.currentTarget as HTMLAnchorElement).style.borderColor = `${C.accent}44`
              }}
              onMouseLeave={(e) => {
                ;(e.currentTarget as HTMLAnchorElement).style.transform = ''
                ;(e.currentTarget as HTMLAnchorElement).style.borderColor = 'rgba(255,255,255,0.05)'
              }}
            >
              <span style={{ fontSize: 28 }}>{card.icon}</span>
              <h3 style={{ fontSize: 14, fontWeight: 600, color: C.text1, margin: '10px 0 4px' }}>
                {card.title}
              </h3>
              <p style={{ fontSize: 12, color: C.accent, margin: 0, fontWeight: 600 }}>{card.count}</p>
            </a>
          ))}
        </div>

        <div
          style={{
            background: C.surface,
            borderRadius: 14,
            padding: 20,
            border: '1px solid rgba(255,255,255,0.05)',
          }}
        >
          <h3 style={{ fontSize: 14, fontWeight: 600, color: C.text2, margin: '0 0 16px' }}>
            가치 카테고리
          </h3>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 10 }}>
            {Object.entries(categoryCounts).map(([cat, count]) => (
              <div
                key={cat}
                style={{
                  background: C.surface2,
                  borderRadius: 10,
                  padding: '12px 14px',
                  textAlign: 'center',
                }}
              >
                <p style={{ fontSize: 20, fontWeight: 700, color: C.accent, margin: '0 0 2px' }}>
                  {count}
                </p>
                <p style={{ fontSize: 12, color: C.text2, margin: 0 }}>
                  {{
                    family: '가족',
                    career: '직업',
                    emotion: '감정',
                    challenge: '도전',
                    peace: '평화',
                    growth: '성장',
                  }[cat]}
                </p>
              </div>
            ))}
          </div>
        </div>
      </div>
    </AppShell>
  )
}
