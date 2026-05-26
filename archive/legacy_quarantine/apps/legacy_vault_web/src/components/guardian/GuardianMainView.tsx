import AppShell from '../layout/AppShell'
import { useGuardianStore } from '../../stores/guardianStore'

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

export default function GuardianMainView() {
  const { vaults, heirs, isDeadManActive, deadManDeadline } = useGuardianStore()

  const activeVaults = vaults.filter((v) => v.status === 'active').length
  const totalHeirs = heirs.length

  return (
    <AppShell>
      <div style={{ maxWidth: 960, margin: '0 auto' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
          <h1 style={{ fontSize: 24, fontWeight: 600, color: C.accent }}>🛡 Guardian</h1>
          <span
            style={{
              fontSize: 12,
              padding: '4px 14px',
              borderRadius: 12,
              background: isDeadManActive ? `${C.accent}18` : `${C.alert}18`,
              color: isDeadManActive ? C.accent : C.alert,
              fontWeight: 600,
            }}
          >
            {isDeadManActive ? `${deadManDeadline}일 데드맨` : '데드맨 비활성'}
          </span>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 12, marginBottom: 24 }}>
          {[
            { label: '활성 보箱', value: activeVaults, color: C.accent },
            { label: '상속인', value: totalHeirs, color: C.accent2 },
            { label: '마지막 핑', value: '1일 전', color: C.text1 },
          ].map((stat) => (
            <div
              key={stat.label}
              style={{
                background: C.surface,
                borderRadius: 14,
                padding: 20,
                border: '1px solid rgba(255,255,255,0.05)',
              }}
            >
              <p style={{ fontSize: 12, color: C.text2, margin: '0 0 8px' }}>{stat.label}</p>
              <p
                style={{
                  fontSize: 28,
                  fontWeight: 700,
                  color: stat.color,
                  margin: 0,
                  lineHeight: 1,
                }}
              >
                {stat.value}
              </p>
            </div>
          ))}
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(220px, 1fr))', gap: 12 }}>
          {[
            { href: '/app/guardian/deadman', icon: '⏱', title: '데드맨 스위치', desc: '기한 설정 관리' },
            { href: '/app/guardian/heirs', icon: '👥', title: '상속인 관리', desc: `${totalHeirs}명 등록됨` },
            { href: '/app/guardian/backups', icon: '🔒', title: '백업 상태', desc: '암호화 확인' },
            { href: '/app/guardian/vaults', icon: '🔓', title: '보箱 복구', desc: '암호 해제' },
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
              <span style={{ fontSize: 24 }}>{card.icon}</span>
              <h3 style={{ fontSize: 14, fontWeight: 600, color: C.text1, margin: '10px 0 4px' }}>
                {card.title}
              </h3>
              <p style={{ fontSize: 12, color: C.text2, margin: 0 }}>{card.desc}</p>
            </a>
          ))}
        </div>
      </div>
    </AppShell>
  )
}
