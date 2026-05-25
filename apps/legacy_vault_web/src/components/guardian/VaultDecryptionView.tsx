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

export default function VaultDecryptionView() {
  const [passphrase, setPassphrase] = useState('')
  const [isUnlocked, setIsUnlocked] = useState(false)
  const [isBiometricAvailable, setIsBiometricAvailable] = useState(false)

  const handleUnlock = () => {
    if (passphrase.length >= 4) {
      setIsUnlocked(true)
    }
  }

  const handleBiometric = () => {
    setIsUnlocked(true)
  }

  return (
    <AppShell>
      <div style={{ maxWidth: 520, margin: '0 auto' }}>
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
          <h1 style={{ fontSize: 20, fontWeight: 600, color: C.text1, margin: 0 }}>보箱 복구</h1>
        </div>

        {!isUnlocked ? (
          <div
            style={{
              background: C.surface,
              borderRadius: 16,
              padding: 28,
              border: '1px solid rgba(255,255,255,0.05)',
              textAlign: 'center',
            }}
          >
            <div style={{ fontSize: 48, marginBottom: 16 }}>🔓</div>
            <p style={{ fontSize: 15, color: C.text1, margin: '0 0 20px' }}>
              복구하려면 비밀번호를 입력하세요
            </p>

            <input
              type="password"
              value={passphrase}
              onChange={(e) => setPassphrase(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && handleUnlock()}
              placeholder="비밀번호"
              style={{
                width: '100%',
                padding: '12px 16px',
                borderRadius: 12,
                border: `1px solid ${C.text2}44`,
                background: C.surface2,
                color: C.text1,
                fontSize: 15,
                marginBottom: 12,
                outline: 'none',
                boxSizing: 'border-box',
              }}
            />

            <button
              onClick={handleUnlock}
              style={{
                width: '100%',
                padding: '14px',
                borderRadius: 12,
                background: C.accent,
                color: '#000',
                border: 'none',
                cursor: 'pointer',
                fontSize: 15,
                fontWeight: 600,
                marginBottom: 16,
              }}
            >
              🔓 해제하기
            </button>

            <div style={{ position: 'relative' }}>
              <div style={{ height: 1, background: `${C.text2}22`, marginBottom: 16 }} />
              <p style={{ fontSize: 12, color: C.text2, margin: '0 0 12px' }}>또는</p>

              <button
                onClick={handleBiometric}
                style={{
                  width: '100%',
                  padding: '12px',
                  borderRadius: 12,
                  background: C.surface2,
                  color: C.text2,
                  border: `1px solid ${C.text2}33`,
                  cursor: isBiometricAvailable ? 'pointer' : 'not-allowed',
                  fontSize: 14,
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  gap: 8,
                }}
              >
                👆 지문 인식
              </button>
              <p style={{ fontSize: 11, color: C.text2, marginTop: 8 }}>
                {isBiometricAvailable ? 'Touch ID / Face ID 사용 가능' : '지문 인식을 설정하세요'}
              </p>
            </div>
          </div>
        ) : (
          <div
            style={{
              background: C.surface,
              borderRadius: 16,
              padding: 28,
              border: `1px solid ${C.accent}44`,
              textAlign: 'center',
            }}
          >
            <div style={{ fontSize: 48, marginBottom: 16 }}>✅</div>
            <p style={{ fontSize: 18, fontWeight: 600, color: C.accent, margin: '0 0 8px' }}>
              보箱이 복구되었습니다
            </p>
            <p style={{ fontSize: 14, color: C.text2, margin: 0 }}>
              3개의 암호화 리소스가 접근 가능합니다
            </p>
          </div>
        )}
      </div>
    </AppShell>
  )
}
