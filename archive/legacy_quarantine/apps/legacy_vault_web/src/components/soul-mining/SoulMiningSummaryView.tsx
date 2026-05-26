import { useSoulMiningStore } from '../../stores/soulMiningStore'
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

export default function SoulMiningSummaryView() {
  const selectedLog = useSoulMiningStore((s) => s.logs[0])

  if (!selectedLog) {
    return (
      <AppShell>
        <div style={{ textAlign: 'center', padding: 48, color: C.text2 }}>요약할 녹음이 없습니다</div>
      </AppShell>
    )
  }

  const emotionPercent = Math.abs(selectedLog.sentiment)
  const emotionColor = selectedLog.sentiment > 0 ? C.accent : C.alert

  const allKeywords = [
    ...new Set(
      useSoulMiningStore
        .getState()
        .logs.flatMap((l) => l.keywords)
    ),
  ]

  return (
    <AppShell>
      <div style={{ maxWidth: 720, margin: '0 auto' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 24 }}>
          <button
            onClick={() => (window.location.href = '/app/mining')}
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
          <h1 style={{ fontSize: 20, fontWeight: 600, color: C.text1, margin: 0 }}>AI 요약</h1>
        </div>

        <div
          style={{
            background: `linear-gradient(135deg, ${C.surface}, ${C.surface2})`,
            borderRadius: 16,
            padding: 24,
            border: `1px solid ${C.accent}22`,
            marginBottom: 16,
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 12 }}>
            <span style={{ fontSize: 16 }}>✨</span>
            <span style={{ fontSize: 13, fontWeight: 600, color: C.accent }}>AI 요약</span>
          </div>
          <p style={{ fontSize: 14, lineHeight: 1.8, color: C.text1, margin: 0 }}>
            {selectedLog.aiSummary ||
              `이 녹음에서는 ${selectedLog.title}에 대한 이야기가 담겨 있습니다. 전반적으로 긍정적/부정적 감정(${selectedLog.sentiment})으로 기록되었습니다.`}
          </p>
        </div>

        <div
          style={{
            background: C.surface,
            borderRadius: 12,
            padding: 20,
            border: '1px solid rgba(255,255,255,0.05)',
            marginBottom: 16,
          }}
        >
          <h3 style={{ fontSize: 13, fontWeight: 600, color: C.text2, margin: '0 0 12px' }}>
            감정 분석
          </h3>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <div
              style={{
                flex: 1,
                height: 8,
                borderRadius: 4,
                background: `${C.text2}22`,
                overflow: 'hidden',
              }}
            >
              <div
                style={{
                  height: '100%',
                  width: `${emotionPercent}%`,
                  background: emotionColor,
                  borderRadius: 4,
                  transition: 'width 0.5s ease',
                }}
              />
            </div>
            <span
              style={{
                fontSize: 14,
                fontWeight: 700,
                color: emotionColor,
                minWidth: 40,
                textAlign: 'right',
              }}
            >
              {selectedLog.sentiment}
            </span>
          </div>
          <div
            style={{
              display: 'flex',
              justifyContent: 'space-between',
              marginTop: 4,
              fontSize: 11,
              color: C.text2,
            }}
          >
            <span>😔 부정적</span>
            <span>😊 긍정적</span>
          </div>
        </div>

        <div
          style={{
            background: C.surface,
            borderRadius: 12,
            padding: 20,
            border: '1px solid rgba(255,255,255,0.05)',
          }}
        >
          <h3 style={{ fontSize: 13, fontWeight: 600, color: C.text2, margin: '0 0 12px' }}>
            주요 키워드
          </h3>
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
            {allKeywords.length > 0 ? (
              allKeywords.map((kw) => (
                <span
                  key={kw}
                  style={{
                    fontSize: 13,
                    color: C.accent,
                    background: `${C.accent}12`,
                    padding: '6px 14px',
                    borderRadius: 20,
                    border: `1px solid ${C.accent}22`,
                  }}
                >
                  #{kw}
                </span>
              ))
            ) : (
              <span style={{ fontSize: 13, color: C.text2 }}>추출된 키워드가 없습니다</span>
            )}
            <span
              style={{
                fontSize: 13,
                color: C.accent2,
                background: `${C.accent2}12`,
                padding: '6px 14px',
                borderRadius: 20,
                border: `1px solid ${C.accent2}22`,
              }}
            >
              + AI 추출
            </span>
          </div>
        </div>
      </div>
    </AppShell>
  )
}
