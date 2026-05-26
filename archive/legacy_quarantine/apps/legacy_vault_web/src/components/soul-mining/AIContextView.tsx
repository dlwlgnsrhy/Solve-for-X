import { useState } from 'react'
import AppShell from '../layout/AppShell'

const C = {
  background: '#0A0A0F',
  surface: '#1A1A2E',
  surface2: '#2A2A3E',
  accent: '#00FF88',
  accent2: '#8B5CF6',
  text1: '#E8E8ED',
  text2: '#8E8EA0',
} as const

const questions = [
  { id: 'q1', text: '오늘 가장 기억에 남는 순간은 무엇이었나요?', category: '감각' },
  { id: 'q2', text: '지난주에 가장 크게 느꼈던 감정은?', category: '감정' },
  { id: 'q3', text: '앞으로 꼭 이루고 싶은 것은 무엇인가요?', category: '목표' },
  { id: 'q4', text: '가장 감사한 사람은 누구인가요?', category: '관계' },
  { id: 'q5', text: '어린 시절 가장 재미있었던 기억을 말해주세요.', category: '기억' },
]

export default function AIContextView() {
  const [answered, setAnswered] = useState<Set<string>>(new Set())
  const [answers, setAnswers] = useState<Record<string, string>>({})

  const handleAnswer = (id: string) => {
    const text = prompt('답변을 입력하세요:')
    if (text) {
      setAnswers((prev) => ({ ...prev, [id]: text }))
      setAnswered((prev) => new Set(prev).add(id))
    }
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
          <h1 style={{ fontSize: 20, fontWeight: 600, color: C.text1, margin: 0 }}>AI 질문</h1>
        </div>

        <p style={{ fontSize: 14, color: C.text2, marginBottom: 20 }}>
          AI가 당신의 생각과 감정을 더 깊이 이해하기 위해 질문합니다.
        </p>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          {questions.map((q, i) => (
            <div
              key={q.id}
              style={{
                background: C.surface,
                borderRadius: 14,
                padding: 20,
                border: answered.has(q.id) ? `1px solid ${C.accent}44` : '1px solid rgba(255,255,255,0.05)',
                transition: 'border-color 0.3s',
              }}
            >
              <div style={{ display: 'flex', gap: 12, alignItems: 'flex-start' }}>
                <span
                  style={{
                    fontSize: 11,
                    background: `${C.accent2}22`,
                    color: C.accent2,
                    padding: '3px 10px',
                    borderRadius: 8,
                    whiteSpace: 'nowrap',
                    fontWeight: 600,
                  }}
                >
                  {q.category}
                </span>
                <div style={{ flex: 1 }}>
                  <p style={{ fontSize: 15, fontWeight: 500, color: C.text1, margin: '0 0 12px' }}>
                    {i + 1}. {q.text}
                  </p>

                  {answered.has(q.id) ? (
                    <div
                      style={{
                        background: C.surface2,
                        padding: 12,
                        borderRadius: 10,
                        fontSize: 13,
                        lineHeight: 1.6,
                        color: C.text1,
                      }}
                    >
                      <span style={{ color: C.accent, fontSize: 12, fontWeight: 600 }}>내 답변: </span>
                      {answers[q.id]}
                    </div>
                  ) : (
                    <button
                      onClick={() => handleAnswer(q.id)}
                      style={{
                        background: 'none',
                        border: `1px solid ${C.accent}66`,
                        color: C.accent,
                        borderRadius: 10,
                        padding: '8px 20px',
                        fontSize: 13,
                        fontWeight: 600,
                        cursor: 'pointer',
                        transition: 'background 0.2s',
                      }}
                      onMouseEnter={(e) => (e.currentTarget.style.background = `${C.accent}11`)}
                      onMouseLeave={(e) => (e.currentTarget.style.background = 'none')}
                    >
                      💬 답변하기
                    </button>
                  )}
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </AppShell>
  )
}
