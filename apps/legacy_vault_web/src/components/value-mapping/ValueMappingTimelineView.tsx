import { useValueMappingStore } from '../../stores/valueMappingStore'
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

export default function ValueMappingTimelineView() {
  const entries = useValueMappingStore((s) => s.entries)
  const sorted = [...entries].sort((a, b) => b.date - a.date)

  return (
    <AppShell>
      <div style={{ maxWidth: 640, margin: '0 auto' }}>
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
          <h1 style={{ fontSize: 20, fontWeight: 600, color: C.text1, margin: 0 }}>타임라인</h1>
        </div>

        {sorted.length === 0 ? (
          <div style={{ textAlign: 'center', padding: 48, color: C.text2 }}>
            아직 기록된 타임라인이 없습니다
          </div>
        ) : (
          <div style={{ position: 'relative', paddingLeft: 24 }}>
            <div
              style={{
                position: 'absolute',
                left: 7,
                top: 0,
                bottom: 0,
                width: 2,
                background: `${C.text2}22`,
              }}
            />

            {sorted.map((entry, i) => {
              const isPositive = entry.sentiment > 0
              return (
                <div key={entry.id} style={{ position: 'relative', marginBottom: 20 }}>
                  <div
                    style={{
                      position: 'absolute',
                      left: -21,
                      top: 8,
                      width: 12,
                      height: 12,
                      borderRadius: '50%',
                      background: isPositive ? C.accent : C.alert,
                      border: `2px solid ${C.background}`,
                    }}
                  />
                  <div
                    style={{
                      marginLeft: 12,
                      background: C.surface,
                      borderRadius: 12,
                      padding: 16,
                      border: '1px solid rgba(255,255,255,0.05)',
                    }}
                  >
                    <span
                      style={{
                        fontSize: 11,
                        color: C.text2,
                        background: C.surface2,
                        padding: '3px 10px',
                        borderRadius: 8,
                      }}
                    >
                      {new Date(entry.date).toLocaleDateString('ko-KR', {
                        year: 'numeric',
                        month: 'long',
                        day: 'numeric',
                      })}
                    </span>
                    <h3 style={{ fontSize: 14, fontWeight: 600, color: C.text1, margin: '8px 0 6px' }}>
                      {entry.title}
                    </h3>
                    <p style={{ fontSize: 13, color: C.text2, margin: '0 0 8px', lineHeight: 1.5 }}>
                      {entry.content.slice(0, 100)}
                      {entry.content.length > 100 ? '...' : ''}
                    </p>
                    <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
                      {entry.keywords.map((kw) => (
                        <span
                          key={kw.id}
                          style={{
                            fontSize: 11,
                            color: C.accent2,
                            background: `${C.accent2}14`,
                            padding: '2px 8px',
                            borderRadius: 6,
                          }}
                        >
                          #{kw.word}
                        </span>
                      ))}
                    </div>
                  </div>
                </div>
              )
            })}
          </div>
        )}
      </div>
    </AppShell>
  )
}
