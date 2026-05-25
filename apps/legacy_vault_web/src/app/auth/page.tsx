'use client'

import { useState } from 'react'

const C = {
  background: '#0A0A0F',
  surface: '#1A1A2E',
  surface2: '#2A2A3E',
  accent: '#00FF88',
  accent2: '#8B5CF6',
  text1: '#E8E8ED',
  text2: '#8E8EA0',
} as const

export default function AuthPage() {
  const [passcode, setPasscode] = useState('')
  const [isWaiting, setIsWaiting] = useState(false)

  const handlePasscode = () => {
    if (passcode.length >= 4) {
      setIsWaiting(true)
    }
  }

  const handleWebAuthn = () => {
    setIsWaiting(true)
  }

  return (
    <div
      style={{
        minHeight: '100vh',
        background: C.background,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
      }}
    >
      <div style={{ maxWidth: 400, width: '100%', padding: 24, textAlign: 'center' }}>
        <div
          style={{
            width: 80,
            height: 80,
            borderRadius: '50%',
            background: `linear-gradient(135deg, ${C.accent}, ${C.accent2})`,
            margin: '0 auto 20px',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            fontSize: 36,
          }}
        >
          🔐
        </div>

        <h1 style={{ fontSize: 22, fontWeight: 600, color: C.text1, margin: '0 0 8px' }}>
          Legacy Vault
        </h1>
        <p style={{ fontSize: 13, color: C.text2, margin: '0 0 32px' }}>
          보箱에 접근하려면 인증하세요
        </p>

        <button
          onClick={handleWebAuthn}
          style={{
            width: '100%',
            padding: '14px',
            borderRadius: 12,
            background: C.surface,
            color: C.text1,
            border: `1px solid ${C.accent}44`,
            cursor: isWaiting ? 'not-allowed' : 'pointer',
            fontSize: 14,
            fontWeight: 600,
            marginBottom: 16,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            gap: 8,
          }}
        >
          🔑 WebAuthn 로그인
        </button>

        <div style={{ position: 'relative', marginBottom: 24 }}>
          <div style={{ height: 1, background: `${C.text2}22`, marginBottom: 20 }} />
          <p style={{ fontSize: 12, color: C.text2, margin: 0 }}>또는</p>
        </div>

        <input
          type="password"
          value={passcode}
          onChange={(e) => setPasscode(e.target.value.replace(/\D/g, '').slice(0, 10))}
          onKeyDown={(e) => e.key === 'Enter' && handlePasscode()}
          placeholder="비밀문구 입력"
          maxLength={10}
          style={{
            width: '100%',
            padding: '12px 16px',
            borderRadius: 12,
            border: `1px solid ${C.text2}44`,
            background: C.surface2,
            color: C.text1,
            fontSize: 16,
            letterSpacing: 4,
            textAlign: 'center',
            marginBottom: 16,
            outline: 'none',
            boxSizing: 'border-box',
          }}
        />

        <button
          onClick={handlePasscode}
          style={{
            width: '100%',
            padding: '14px',
            borderRadius: 12,
            background: C.accent,
            color: '#000',
            border: 'none',
            cursor: isWaiting ? 'not-allowed' : 'pointer',
            fontSize: 15,
            fontWeight: 600,
          }}
        >
          {isWaiting ? '처리 중...' : '해제하기'}
        </button>

        <p
          style={{
            fontSize: 11,
            color: C.text2,
            marginTop: 20,
            lineHeight: 1.5,
          }}
        >
          WebAuthn이 지원되지 않는 경우 비밀번호를 사용하세요.
        </p>
      </div>
    </div>
  )
}
