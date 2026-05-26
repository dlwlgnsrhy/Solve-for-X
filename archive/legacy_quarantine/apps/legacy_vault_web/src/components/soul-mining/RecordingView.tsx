import { useState, useRef } from 'react'
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

const sampleWaveform = Array.from({ length: 60 }, () => Math.random())

export default function RecordingView() {
  const [elapsed, setElapsed] = useState(0)
  const [waveformData] = useState(() => sampleWaveform)
  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null)
  const addLog = useSoulMiningStore((s) => s.addLog)

  const handleStart = () => {
    setElapsed(0)
    intervalRef.current = setInterval(() => setElapsed((n) => n + 1), 1000)
  }

  const handleStop = () => {
    if (intervalRef.current) clearInterval(intervalRef.current)
    const mins = Math.floor(elapsed / 60)
    const secs = elapsed % 60
    addLog({
      id: `log-${Date.now()}`,
      title: `녹음 ${new Date().toLocaleDateString('ko-KR')}`,
      recordingDate: Date.now(),
      sentiment: 0,
      durationMs: elapsed * 1000,
      keywords: [],
    })
    setElapsed(0)
  }

  const formatTime = (s: number) => {
    const m = Math.floor(s / 60)
    const sec = s % 60
    return `${String(m).padStart(2, '0')}:${String(sec).padStart(2, '0')}`
  }

  return (
    <AppShell>
      <div style={{ maxWidth: 720, margin: '0 auto', padding: '0 8px' }}>
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
          <h1 style={{ fontSize: 20, fontWeight: 600, color: C.text1, margin: 0 }}>녹음하기</h1>
        </div>

        <div
          style={{
            background: C.surface,
            borderRadius: 16,
            padding: 24,
            border: `1px solid rgba(255,255,255,0.05)`,
          }}
        >
          <div
            style={{
              textAlign: 'center',
              fontSize: 48,
              fontFamily: 'monospace',
              fontWeight: 700,
              color: C.accent,
              marginBottom: 24,
              letterSpacing: 4,
            }}
          >
            {formatTime(elapsed)}
          </div>

          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: 2,
              height: 60,
              marginBottom: 24,
              padding: '8px 0',
            }}
          >
            {waveformData.map((h, i) => (
              <div
                key={i}
                style={{
                  flex: 1,
                  height: `${h * 100}%`,
                  background: i < elapsed ? C.accent : `${C.text2}33`,
                  borderRadius: 2,
                  transition: 'background 0.3s',
                  minWidth: 3,
                }}
              />
            ))}
          </div>

          <div style={{ display: 'flex', justifyContent: 'center', gap: 16 }}>
            {!elapsed ? (
              <button
                onClick={handleStart}
                style={{
                  width: 72,
                  height: 72,
                  borderRadius: '50%',
                  background: C.accent,
                  border: 'none',
                  cursor: 'pointer',
                  fontSize: 28,
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                }}
              >
                🎤
              </button>
            ) : (
              <>
                <button
                  onClick={handleStart}
                  style={{
                    padding: '12px 32px',
                    borderRadius: 12,
                    background: C.surface2,
                    color: C.text1,
                    border: `1px solid ${C.text2}44`,
                    cursor: 'pointer',
                    fontSize: 14,
                    fontWeight: 600,
                  }}
                >
                  ▶ 일시정지
                </button>
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
                  ⏹ 중지
                </button>
              </>
            )}
          </div>
        </div>

        <p style={{ textAlign: 'center', fontSize: 12, color: C.text2, marginTop: 16 }}>
          마이크에 말해주세요. 녹음은 로컬设备上 저장됩니다.
        </p>
      </div>
    </AppShell>
  )
}
