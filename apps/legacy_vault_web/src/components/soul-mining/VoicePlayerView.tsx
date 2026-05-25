import { useState } from 'react'
import AppShell from '../layout/AppShell'
import { useSoulMiningStore } from '../../stores/soulMiningStore'

const C = {
  background: '#0A0A0F',
  surface: '#1A1A2E',
  surface2: '#2A2A3E',
  accent: '#00FF88',
  accent2: '#8B5CF6',
  text1: '#E8E8ED',
  text2: '#8E8EA0',
} as const

export default function VoicePlayerView() {
  const selectedLog = useSoulMiningStore((s) => s.logs[0])
  const [isPlaying, setIsPlaying] = useState(false)
  const [progress, setProgress] = useState(35)

  if (!selectedLog) {
    return (
      <AppShell>
        <div
          style={{
            textAlign: 'center',
            padding: 48,
            color: C.text2,
            fontSize: 15,
          }}
        >
          재생할 녹음이 없습니다
        </div>
      </AppShell>
    )
  }

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
          <h1 style={{ fontSize: 20, fontWeight: 600, color: C.text1, margin: 0 }}>
            {selectedLog.title}
          </h1>
        </div>

        <div
          style={{
            background: C.surface,
            borderRadius: 16,
            padding: 24,
            border: `1px solid rgba(255,255,255,0.05)`,
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: 16, marginBottom: 20 }}>
            <button
              onClick={() => setIsPlaying(!isPlaying)}
              style={{
                width: 48,
                height: 48,
                borderRadius: '50%',
                background: C.accent,
                border: 'none',
                cursor: 'pointer',
                fontSize: 20,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                flexShrink: 0,
              }}
            >
              {isPlaying ? '⏸' : '▶'}
            </button>
            <div style={{ flex: 1 }}>
              <div
                style={{
                  height: 6,
                  borderRadius: 3,
                  background: `${C.text2}22`,
                  overflow: 'hidden',
                  cursor: 'pointer',
                }}
              >
                <div
                  style={{
                    height: '100%',
                    width: `${progress}%`,
                    background: `linear-gradient(90deg, ${C.accent}, ${C.accent2})`,
                    borderRadius: 3,
                    transition: 'width 0.3s',
                  }}
                />
              </div>
              <div
                style={{
                  display: 'flex',
                  justifyContent: 'space-between',
                  marginTop: 6,
                  fontSize: 11,
                  color: C.text2,
                }}
              >
                <span>
                  {Math.floor((progress / 100) * (selectedLog.durationMs / 1000 / 60))}:{String(
                    Math.floor(((progress / 100) * (selectedLog.durationMs / 1000)) % 60)
                  ).padStart(2, '0')}
                </span>
                <span>
                  {Math.floor(selectedLog.durationMs / 1000 / 60)}:{String(
                    Math.floor((selectedLog.durationMs / 1000) % 60)
                  ).padStart(2, '0')}
                </span>
              </div>
            </div>
          </div>

          {selectedLog.transcript ? (
            <div style={{ marginTop: 16 }}>
              <h3 style={{ fontSize: 13, fontWeight: 600, color: C.accent, marginBottom: 8 }}>
                📝 Transcript
              </h3>
              <p
                style={{
                  fontSize: 14,
                  lineHeight: 1.8,
                  color: C.text1,
                  background: C.surface2,
                  padding: 16,
                  borderRadius: 10,
                }}
              >
                {selectedLog.transcript}
              </p>
            </div>
          ) : (
            <div
              style={{
                marginTop: 16,
                padding: 16,
                borderRadius: 10,
                background: C.surface2,
                border: `1px dashed ${C.text2}33`,
                textAlign: 'center',
                fontSize: 13,
                color: C.text2,
              }}
            >
              STT 변환 대기 중...
            </div>
          )}

          <div
            style={{
              display: 'flex',
              gap: 12,
              marginTop: 16,
              flexWrap: 'wrap',
            }}
          >
            <span
              style={{
                fontSize: 12,
                color: C.text2,
                background: C.surface2,
                padding: '4px 12px',
                borderRadius: 8,
              }}
            >
              감정: {selectedLog.sentiment > 0 ? '😊 긍정' : '😔 부정'} ({selectedLog.sentiment})
            </span>
            <span style={{ fontSize: 12, color: C.text2, background: C.surface2, padding: '4px 12px', borderRadius: 8 }}>
              길이: {Math.floor(selectedLog.durationMs / 1000 / 60)}분
            </span>
          </div>
        </div>
      </div>
    </AppShell>
  )
}
