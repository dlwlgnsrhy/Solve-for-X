import AppShell from '../layout/AppShell'

const C = {
  background: '#0A0A0F',
  surface: '#1A1A2E',
  surface2: '#2A2A3E',
  accent: '#00FF88',
  accent2: '#8B5CF6',
  alert: '#FF3860',
  text1: '#E8E8ED',
  text2: '#8E8EA0',
} as const

export default function HomeDashboardView() {
  return (
    <AppShell>
      <div style={{ maxWidth: 960, margin: '0 auto' }}>
        <h1 style={{ fontSize: 28, fontWeight: 600, color: C.text1, margin: '0 0 8px' }}>
          Legacy Vault
        </h1>
        <p style={{ fontSize: 14, color: C.text2, margin: '0 0 28px' }}>
          당신의 이야기를 안전하게 보존하세요
        </p>

        <div
          style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fill, minmax(200px, 1fr))',
            gap: 12,
            marginBottom: 24,
          }}
        >
          {[
            {
              href: '/app/mining',
              icon: '🎤',
              title: 'Soul Mining',
              desc: '음성 기록 & AI 분석',
              accent: C.accent,
            },
            {
              href: '/app/guardian',
              icon: '🛡',
              title: 'Guardian',
              desc: '디지털 유산 관리',
              accent: C.accent2,
            },
            {
              href: '/app/agent',
              icon: '🤖',
              title: 'Legacy Agent',
              desc: 'AI 기억 대화 파트너',
              accent: '#FFB347',
            },
            {
              href: '/app/values',
              icon: '🧠',
              title: 'Value Mapping',
              desc: '가치관 매핑 & 시각화',
              accent: '#4ECDC4',
            },
          ].map((card) => (
            <a
              key={card.title}
              href={card.href}
              style={{
                textDecoration: 'none',
                background: C.surface,
                borderRadius: 16,
                padding: 24,
                border: `1px solid ${card.accent}22`,
                transition: 'transform 0.15s ease, border-color 0.15s ease',
              }}
              onMouseEnter={(e) => {
                ;(e.currentTarget as HTMLAnchorElement).style.transform = 'translateY(-3px)'
                ;(e.currentTarget as HTMLAnchorElement).style.borderColor = `${card.accent}55`
              }}
              onMouseLeave={(e) => {
                ;(e.currentTarget as HTMLAnchorElement).style.transform = ''
                ;(e.currentTarget as HTMLAnchorElement).style.borderColor = `${card.accent}22`
              }}
            >
              <span style={{ fontSize: 32 }}>{card.icon}</span>
              <h3
                style={{
                  fontSize: 16,
                  fontWeight: 600,
                  color: card.accent,
                  margin: '12px 0 6px',
                }}
              >
                {card.title}
              </h3>
              <p style={{ fontSize: 13, color: C.text2, margin: 0 }}>{card.desc}</p>
            </a>
          ))}
        </div>

        <div
          style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(4, 1fr)',
            gap: 12,
          }}
        >
          {[
            { label: '녹음 기록', value: '3', icon: '🎤' },
            { label: '잠긴 보箱', value: '2', icon: '🔒' },
            { label: '상속인', value: '2', icon: '👥' },
            { label: '대화', value: '42', icon: '💬' },
          ].map((stat) => (
            <div
              key={stat.label}
              style={{
                background: C.surface,
                borderRadius: 12,
                padding: '16px 18px',
                border: '1px solid rgba(255,255,255,0.05)',
              }}
            >
              <span style={{ fontSize: 18 }}>{stat.icon}</span>
              <p
                style={{
                  fontSize: 22,
                  fontWeight: 700,
                  color: C.text1,
                  margin: '8px 0 2px',
                }}
              >
                {stat.value}
              </p>
              <p style={{ fontSize: 12, color: C.text2, margin: 0 }}>{stat.label}</p>
            </div>
          ))}
        </div>
      </div>
    </AppShell>
  )
}
