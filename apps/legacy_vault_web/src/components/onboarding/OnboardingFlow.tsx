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

export default function OnboardingFlow() {
  const [step, setStep] = useState(0)

  const steps = [
    {
      title: 'Legacy Vault에 오신 것을 환영합니다',
      desc: '당신의 기억과 이야기를 안전하게 보존하는 디지털 유산 관리 도구입니다.',
      icon: '🏠',
    },
    {
      title: '프라이버시는 당신의 것입니다',
      desc: '모든 데이터는 기기 내에서 암호화되어 로컬에 저장됩니다. 외부 서버에 절대 전송되지 않습니다.',
      icon: '🔒',
    },
    {
      title: '비밀문구를 설정하세요',
      desc: '보통 4자리 이상의 numeric passcode로 Vaults를 잠급니다. 분실 시 복구가 불가능합니다.',
      icon: '🔑',
    },
    {
      title: '준비 완료!',
      desc: '이제 Soul Mining, Guardian, Legacy Agent를 시작할 수 있습니다.',
      icon: '🚀',
    },
  ]

  if (step < 3) {
    return (
      <div
        style={{
          minHeight: '100vh',
          background: C.background,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          padding: 24,
        }}
      >
        <div style={{ maxWidth: 440, textAlign: 'center' }}>
          <div style={{ fontSize: 56, marginBottom: 20 }}>{steps[step].icon}</div>
          <h1 style={{ fontSize: 22, fontWeight: 700, color: C.text1, margin: '0 0 12px' }}>
            {steps[step].title}
          </h1>
          <p style={{ fontSize: 14, color: C.text2, margin: '0 0 32px', lineHeight: 1.7 }}>
            {steps[step].desc}
          </p>

          <div
            style={{
              display: 'flex',
              gap: 6,
              justifyContent: 'center',
              marginBottom: 32,
            }}
          >
            {steps.map((_, i) => (
              <div
                key={i}
                style={{
                  width: i === step ? 24 : 8,
                  height: 8,
                  borderRadius: 4,
                  background: i === step ? C.accent : `${C.text2}33`,
                  transition: 'all 0.3s',
                }}
              />
            ))}
          </div>

          <div style={{ display: 'flex', gap: 12, justifyContent: 'center' }}>
            {step > 0 && (
              <button
                onClick={() => setStep(s => s - 1)}
                style={{
                  padding: '13px 28px',
                  borderRadius: 12,
                  background: C.surface,
                  color: C.text2,
                  border: `1px solid ${C.text2}33`,
                  cursor: 'pointer',
                  fontSize: 14,
                }}
              >
                이전
              </button>
            )}
            <button
              onClick={() => setStep(s => s + 1)}
              style={{
                padding: '13px 36px',
                borderRadius: 12,
                background: C.accent,
                color: '#000',
                border: 'none',
                cursor: 'pointer',
                fontSize: 14,
                fontWeight: 600,
              }}
            >
              {step === 2 ? '완료' : '다음'}
            </button>
          </div>
        </div>
      </div>
    )
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
      <div style={{ textAlign: 'center' }}>
        <div style={{ fontSize: 64, marginBottom: 20 }}>🎉</div>
        <h1 style={{ fontSize: 28, fontWeight: 700, color: C.accent, margin: '0 0 12px' }}>
          시작하세요
        </h1>
        <a
          href="/app"
          style={{
            display: 'inline-block',
            padding: '14px 48px',
            borderRadius: 14,
            background: C.accent2,
            color: '#fff',
            textDecoration: 'none',
            fontSize: 16,
            fontWeight: 600,
          }}
        >
          대시보드로 이동
        </a>
      </div>
    </div>
  )
}
