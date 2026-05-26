import { useState } from 'react'
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

export default function GuardianDeadManView() {
  const { isDeadManActive, deadManDeadline, updateDeadManSettings } = useGuardianStore()
  const [daysInput, setDaysInput] = useState(String(deadManDeadline))

  const handleStart = () => {
    const days = parseInt(daysInput, 10)
    if (days > 0) updateDeadManSettings(days, true)
  }

  const handleStop = () => updateDeadManSettings(deadManDeadline, false)

  return (
    <AppShell>
      <div style={{ maxWidth: 640, margin: '0 auto' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 24 }}>
          <button
            onClick={() => (window.location.href = '/app/guardian')}
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
          <h1 style={{ fontSize: 20, fontWeight: 600, color: C.text1, margin: 0 }}>데드맨 스위치</h1>
        </div>

        <div
          style={{
            background: C.surface,
            borderRadius: 16,
            padding: 28,
            border: '1px solid rgba(255,255,255,0.05)',
            textAlign: 'center',
          }}
        >
          <div style={{ fontSize: 48, marginBottom: 16 }}>⏱</div>

          {isDeadManActive ? (
            <>
              <p style={{ fontSize: 15, color: C.text1, margin: '0 0 8px' }}>
                데드맨 스위치가 활성화되었습니다
              </p>
              <p style={{ fontSize: 36, fontWeight: 700, color: C.accent, margin: '0 0 8px' }}>{deadManDeadline}</p>
              <p style={{ fontSize: 13, color: C.text2, margin: '0 0 24px' }}>일 남음</p>

              <button
                onClick={handleStop}
                style={{
                  padding: '12px 32px',
                  borderRadius: 12,
                  background: C.alert,
                  color: '#fff',
                  border: 'none',
                  cursor: 'pointer',
                  fontSize: 14,
                  fontWeight: 600,
                }}
              >
                🔒 데드맨 중지
              </button>
            </>
          ) : (
            <>
              <p style={{ fontSize: 15, color: C.text1, margin: '0 0 16px' }}>
                정기 핑을 보내지 않으면 정해진 일 후 알림이 발송됩니다
              </p>

              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 12, marginBottom: 20 }}>
                <input
                  type="number"
                  min={1}
                  max={365}
                  value={daysInput}
                  onChange={(e) => setDaysInput(e.target.value)}
                  style={{
                    width: 100,
                    padding: '10px 14px',
                    borderRadius: 10,
                    border: `1px solid ${C.text2}44`,
                    background: C.surface2,
                    color: C.text1,
                    fontSize: 18,
                    fontWeight: 600,
                    textAlign: 'center',
                    outline: 'none',
                  }}
                />
                <span style={{ fontSize: 14, color: C.text2 }}>일</span>
              </div>

              <button
                onClick={handleStart}
                style={{
                  padding: '14px 36px',
                  borderRadius: 12,
                  background: C.accent,
                  color: '#000',
                  border: 'none',
                  cursor: 'pointer',
                  fontSize: 15,
                  fontWeight: 600,
                }}
              >
                ▶ 시작하기
              </button>
            </>
          )}
        </div>
      </div>
    </AppShell>
  )
}
