import { useState, useRef, useEffect } from 'react'
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

export default function LegacyAgentChatView() {
  const { messages, sendMessage, clearMessages } = useLegacyAgentStore()
  const [input, setInput] = useState('')
  const messagesEndRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages])

  const handleSend = () => {
    if (input.trim()) {
      sendMessage(input.trim())
      setInput('')
    }
  }

  return (
    <AppShell>
      <div style={{ display: 'flex', flexDirection: 'column', height: 'calc(100vh - 64px)' }}>
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: 12,
            padding: '16px 24px',
            borderBottom: `1px solid ${C.surface2}`,
          }}
        >
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
          <h1 style={{ fontSize: 18, fontWeight: 600, color: C.text1, margin: 0, flex: 1 }}>
            {useLegacyAgentStore.getState().personaName}
          </h1>
          <button
            onClick={clearMessages}
            style={{
              background: 'none',
              border: 'none',
              color: C.text2,
              cursor: 'pointer',
              fontSize: 12,
              padding: '4px 10px',
            }}
          >
            🗑 초기화
          </button>
        </div>

        <div style={{ flex: 1, overflowY: 'auto', padding: '20px 24px' }}>
          {messages.map((msg) => (
            <div
              key={msg.id}
              style={{
                display: 'flex',
                justifyContent: msg.role === 'user' ? 'flex-end' : 'flex-start',
                marginBottom: 12,
              }}
            >
              <div
                style={{
                  maxWidth: '75%',
                  padding: '12px 16px',
                  borderRadius: 16,
                  background:
                    msg.role === 'user'
                      ? `linear-gradient(135deg, ${C.accent}, ${C.accent2})`
                      : C.surface,
                  color: msg.role === 'user' ? '#000' : C.text1,
                  borderBottomRightRadius: msg.role === 'user' ? 4 : 16,
                  borderBottomLeftRadius: msg.role === 'assistant' ? 4 : 16,
                  fontSize: 14,
                  lineHeight: 1.6,
                }}
              >
                <p style={{ margin: 0 }}>{msg.content}</p>
              </div>
            </div>
          ))}
          <div ref={messagesEndRef} />
        </div>

        <div
          style={{
            display: 'flex',
            gap: 12,
            padding: '16px 24px',
            borderTop: `1px solid ${C.surface2}`,
          }}
        >
          <input
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && handleSend()}
            placeholder="메시지를 입력하세요..."
            style={{
              flex: 1,
              padding: '12px 16px',
              borderRadius: 14,
              border: `1px solid ${C.text2}33`,
              background: C.surface,
              color: C.text1,
              fontSize: 14,
              outline: 'none',
            }}
          />
          <button
            onClick={handleSend}
            style={{
              padding: '12px 24px',
              borderRadius: 14,
              background: C.accent,
              color: '#000',
              border: 'none',
              cursor: 'pointer',
              fontSize: 14,
              fontWeight: 600,
            }}
          >
            전송
          </button>
        </div>
      </div>
    </AppShell>
  )
}
