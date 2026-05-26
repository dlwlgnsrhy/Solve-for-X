import { useState } from 'react'
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

export default function LegacyAgentPersonaView() {
  const { personaName, personaVoice, personaStyle, updatePersona } = useLegacyAgentStore()
  const [name, setName] = useState(personaName)

  const handleTrain = () => {
    alert('퍼소나 교육이 시작됩니다...')
  }

  return (
    <AppShell>
      <div style={{ maxWidth: 640, margin: '0 auto' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 24 }}>
          <button
            onClick={() => (window.location.href = '/app/agent')}
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
          <h1 style={{ fontSize: 20, fontWeight: 600, color: C.text1, margin: 0 }}>퍼소나 설정</h1>
        </div>

        <div
          style={{
            background: C.surface,
            borderRadius: 16,
            padding: 28,
            border: '1px solid rgba(255,255,255,0.05)',
            marginBottom: 16,
          }}
        >
          <div style={{ textAlign: 'center', marginBottom: 24 }}>
            <div
              style={{
                width: 100,
                height: 100,
                borderRadius: '50%',
                background: `linear-gradient(135deg, ${C.accent}, ${C.accent2})`,
                margin: '0 auto 12px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                fontSize: 44,
              }}
            >
              🤖
            </div>
            <p style={{ fontSize: 13, color: C.text2 }}>현재 퍼소나</p>
          </div>

          <div style={{ marginBottom: 20 }}>
            <label style={{ fontSize: 13, color: C.text2, display: 'block', marginBottom: 8 }}>
              에이전트 이름
            </label>
            <input
              value={name}
              onChange={(e) => setName(e.target.value)}
              style={{
                width: '100%',
                padding: '11px 14px',
                borderRadius: 10,
                border: `1px solid ${C.text2}44`,
                background: C.surface2,
                color: C.text1,
                fontSize: 14,
                outline: 'none',
                boxSizing: 'border-box',
              }}
            />
          </div>

          <div style={{ marginBottom: 20 }}>
            <label style={{ fontSize: 13, color: C.text2, display: 'block', marginBottom: 8 }}>
              성우 선택
            </label>
            <select
              style={{
                width: '100%',
                padding: '11px 14px',
                borderRadius: 10,
                border: `1px solid ${C.text2}44`,
                background: C.surface2,
                color: C.text1,
                fontSize: 14,
                outline: 'none',
                boxSizing: 'border-box',
              }}
            >
              <option value="warm-male">따뜻한 남성</option>
              <option value="warm-female">따뜻한 여성</option>
              <option value="calm-male">차분한 남성</option>
              <option value="calm-female">차분한 여성</option>
            </select>
          </div>

          <div style={{ marginBottom: 24 }}>
            <label style={{ fontSize: 13, color: C.text2, display: 'block', marginBottom: 8 }}>
              대화 스타일
            </label>
            <select
              style={{
                width: '100%',
                padding: '11px 14px',
                borderRadius: 10,
                border: `1px solid ${C.text2}44`,
                background: C.surface2,
                color: C.text1,
                fontSize: 14,
                outline: 'none',
                boxSizing: 'border-box',
              }}
            >
              <option value="empathetic">공감적</option>
              <option value="analytical">분석적</option>
              <option value="storytelling">스토리텔링</option>
              <option value="philosophical">철학적</option>
            </select>
          </div>

          <button
            onClick={handleTrain}
            style={{
              width: '100%',
              padding: '14px',
              borderRadius: 12,
              background: `linear-gradient(135deg, ${C.accent}, ${C.accent2})`,
              color: '#000',
              border: 'none',
              cursor: 'pointer',
              fontSize: 15,
              fontWeight: 600,
            }}
          >
            🎓 교육하기
          </button>
        </div>
      </div>
    </AppShell>
  )
}
