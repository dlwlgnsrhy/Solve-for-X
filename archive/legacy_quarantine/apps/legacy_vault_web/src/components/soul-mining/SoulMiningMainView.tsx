import AppShell from '../layout/AppShell'
import { useSoulMiningStore } from '../../stores/soulMiningStore'

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

export default function SoulMiningMainView() {
  const logs = useSoulMiningStore((s) => s.logs)

  return (
    <AppShell>
      <div style={{ maxWidth: 960, margin: '0 auto' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
          <h1 style={{ fontSize: 24, fontWeight: 600, color: C.accent }}>Soul Mining</h1>
          <span style={{ fontSize: 13, color: C.text2 }}>
            {logs.length}개의 녹음 기록
          </span>
        </div>

        <div style={{ display: 'flex', gap: 12, marginBottom: 20 }}>
          <button
            style={{
              background: C.accent,
              color: '#000',
              border: 'none',
              borderRadius: 16,
              padding: '14px 28px',
              fontWeight: 600,
              fontSize: 15,
              cursor: 'pointer',
            }}
          >
            🎤 Start Recording
          </button>
          <button
            style={{
              background: C.accent2,
              color: '#fff',
              border: 'none',
              borderRadius: 16,
              padding: '14px 28px',
              fontWeight: 600,
              fontSize: 15,
              cursor: 'pointer',
            }}
          >
            📄 AI Prompt
          </button>
        </div>

        <div
          style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))',
            gap: 12,
          }}
        >
          {logs.map((log) => (
            <div
              key={log.id}
              style={{
                background: C.surface2,
                borderRadius: 12,
                padding: 16,
                border: '1px solid rgba(255,255,255,0.05)',
                cursor: 'pointer',
                transition: 'transform 0.15s ease, border-color 0.15s ease',
              }}
              onMouseEnter={(e) => {
                ;(e.currentTarget as HTMLDivElement).style.transform = 'translateY(-2px)'
                ;(e.currentTarget as HTMLDivElement).style.borderColor = `${C.accent}44`
              }}
              onMouseLeave={(e) => {
                ;(e.currentTarget as HTMLDivElement).style.transform = ''
                ;(e.currentTarget as HTMLDivElement).style.borderColor = 'rgba(255,255,255,0.05)'
              }}
            >
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                <h3 style={{ fontSize: 14, fontWeight: 600, color: C.text1, margin: 0 }}>{log.title}</h3>
                {log.aiSummary && (
                  <span
                    style={{
                      fontSize: 11,
                      background: `${C.accent2}22`,
                      color: C.accent2,
                      padding: '2px 8px',
                      borderRadius: 8,
                      whiteSpace: 'nowrap',
                    }}
                  >
                    AI 완료
                  </span>
                )}
              </div>
              <p style={{ fontSize: 12, color: C.text2, margin: '6px 0 0' }}>
                {new Date(log.recordingDate).toLocaleDateString('ko-KR', {
                  year: 'numeric',
                  month: 'long',
                  day: 'numeric',
                })}
              </p>
              {log.keywords.length > 0 && (
                <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginTop: 10 }}>
                  {log.keywords.slice(0, 3).map((kw) => (
                    <span
                      key={kw}
                      style={{
                        fontSize: 11,
                        color: C.accent,
                        background: `${C.accent}11`,
                        padding: '2px 8px',
                        borderRadius: 6,
                      }}
                    >
                      #{kw}
                    </span>
                  ))}
                  {log.keywords.length > 3 && (
                    <span style={{ fontSize: 11, color: C.text2 }}>+{log.keywords.length - 3}</span>
                  )}
                </div>
              )}
              <div
                style={{
                  marginTop: 10,
                  height: 3,
                  borderRadius: 2,
                  background: `${C.text2}22`,
                  overflow: 'hidden',
                }}
              >
                <div
                  style={{
                    height: '100%',
                    width: `${Math.abs(log.sentiment)}%`,
                    background: log.sentiment > 0 ? C.accent : C.alert,
                    borderRadius: 2,
                  }}
                />
              </div>
            </div>
          ))}
        </div>
      </div>
    </AppShell>
  )
}
