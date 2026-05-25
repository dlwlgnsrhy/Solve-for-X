import AppShell from '../layout/AppShell'
import { useLegacyAgentStore } from '../../stores/legacyAgentStore'

const C = {
  background: '#0A0A0F',
  surface: '#1A1A2E',
  surface2: '#2A2A3E',
  accent: '#00FF88',
  accent2: '#8B5CF6',
  text1: '#E8E8ED',
  text2: '#8E8EA0',
} as const

export default function LegacyAgentMainView() {
  const { personaName, conversationCount } = useLegacyAgentStore()

  return (
    <AppShell>
      <div style={{ maxWidth: 720, margin: '0 auto' }}>
        <h1 style={{ fontSize: 24, fontWeight: 600, color: C.accent, marginBottom: 24 }}>
          🤖 Legacy Agent
        </h1>

        <div
          style={{
            background: C.surface,
            borderRadius: 20,
            padding: 32,
            border: '1px solid rgba(255,255,255,0.05)',
            textAlign: 'center',
            marginBottom: 20,
          }}
        >
          <div
            style={{
              width: 96,
              height: 96,
              borderRadius: '50%',
              background: `linear-gradient(135deg, ${C.accent}, ${C.accent2})`,
              margin: '0 auto 16px',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              fontSize: 40,
            }}
          >
            🤖
          </div>
          <h2 style={{ fontSize: 20, fontWeight: 600, color: C.text1, margin: '0 0 8px' }}>
            {personaName}
          </h2>
          <p style={{ fontSize: 13, color: C.text2, margin: '0 0 20px' }}>
            당신의 기억과 이야기를 보존하는 AI 파트너
          </p>

          <div style={{ display: 'flex', justifyContent: 'center', gap: 24, marginBottom: 24 }}>
            <div>
              <p style={{ fontSize: 24, fontWeight: 700, color: C.accent, margin: '0 0 4px' }}>
                {conversationCount}
              </p>
              <p style={{ fontSize: 12, color: C.text2, margin: 0 }}>대화 횟수</p>
            </div>
            <div>
              <p style={{ fontSize: 24, fontWeight: 700, color: C.accent2, margin: '0 0 4px' }}>
                { personaName.length }
              </p>
              <p style={{ fontSize: 12, color: C.text2, margin: 0 }}>퍼소나</p>
            </div>
          </div>

          <div style={{ display: 'flex', gap: 12, justifyContent: 'center' }}>
            <a
              href="/app/agent/chat"
              style={{
                padding: '14px 32px',
                borderRadius: 14,
                background: C.accent,
                color: '#000',
                textDecoration: 'none',
                fontSize: 15,
                fontWeight: 600,
                border: 'none',
                cursor: 'pointer',
              }}
            >
              💬 대화 시작
            </a>
            <a
              href="/app/agent/persona"
              style={{
                padding: '14px 32px',
                borderRadius: 14,
                background: C.surface2,
                color: C.text1,
                textDecoration: 'none',
                fontSize: 15,
                fontWeight: 600,
                border: `1px solid ${C.text2}33`,
                cursor: 'pointer',
              }}
            >
              ⚙ 퍼소나 설정
            </a>
          </div>
        </div>
      </div>
    </AppShell>
  )
}
