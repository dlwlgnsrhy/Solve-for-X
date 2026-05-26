import { useState } from 'react'
import AppShell from '../layout/AppShell'
import { useValueMappingStore } from '../../stores/valueMappingStore'

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

export default function ValueView() {
  const selectedEntryId = useValueMappingStore((s) => s.selectedEntryId)
  const entries = useValueMappingStore((s) => s.entries)
  const selected = entries.find((e) => e.id === selectedEntryId) || entries[0]

  if (!selected) {
    return (
      <AppShell>
        <div style={{ textAlign: 'center', padding: 48, color: C.text2 }}>표시할 기록이 없습니다</div>
      </AppShell>
    )
  }

  const relatedEntries = entries.filter((e) =>
    selected.relatedEntryIds.includes(e.id)
  )

  return (
    <AppShell>
      <div style={{ maxWidth: 720, margin: '0 auto' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 24 }}>
          <button
            onClick={() => (window.location.href = '/app/values')}
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
          <h1 style={{ fontSize: 20, fontWeight: 600, color: C.text1, margin: 0 }}>기록 상세</h1>
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
          <div
            style={{
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'flex-start',
              marginBottom: 16,
            }}
          >
            <span
              style={{
                fontSize: 12,
                color: C.text2,
                background: C.surface2,
                padding: '4px 12px',
                borderRadius: 10,
              }}
            >
              {new Date(selected.date).toLocaleDateString('ko-KR', {
                year: 'numeric',
                month: 'long',
                day: 'numeric',
              })}
            </span>
            <span
              style={{
                fontSize: 14,
                fontWeight: 700,
                color: selected.sentiment > 0 ? C.accent : C.alert,
              }}
            >
              {selected.sentiment > 0 ? '😊' : '😔'} {selected.sentiment}
            </span>
          </div>

          <h2 style={{ fontSize: 18, fontWeight: 600, color: C.text1, margin: '0 0 12px' }}>
            {selected.title}
          </h2>

          <p style={{ fontSize: 15, lineHeight: 1.8, color: C.text1, margin: '0 0 20px' }}>
            {selected.content}
          </p>

          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8, marginBottom: 20 }}>
            {selected.keywords.map((kw) => (
              <span
                key={kw.id}
                style={{
                  fontSize: 12,
                  color: C.accent,
                  background: `${C.accent}12`,
                  padding: '5px 14px',
                  borderRadius: 16,
                  border: `1px solid ${C.accent}22`,
                }}
              >
                #{kw.word}
              </span>
            ))}
          </div>

          <p style={{ fontSize: 15, lineHeight: 1.8, color: C.text1, margin: 0 }}>
            📝 녹음 스크립트: {selected.title}에 대한 이야기에서 중요한 가치관이 드러납니다.
          </p>
        </div>

        {relatedEntries.length > 0 && (
          <div
            style={{
              background: C.surface,
              borderRadius: 14,
              padding: 20,
              border: '1px solid rgba(255,255,255,0.05)',
            }}
          >
            <h3 style={{ fontSize: 14, fontWeight: 600, color: C.text2, margin: '0 0 12px' }}>
              관련 기록
            </h3>
            {relatedEntries.map((re) => (
              <div
                key={re.id}
                style={{
                  padding: '10px 14px',
                  background: C.surface2,
                  borderRadius: 10,
                  marginBottom: 8,
                  fontSize: 13,
                  color: C.text1,
                  cursor: 'pointer',
                }}
              >
                {re.title} — {re.content.slice(0, 60)}...
              </div>
            ))}
          </div>
        )}
      </div>
    </AppShell>
  )
}
