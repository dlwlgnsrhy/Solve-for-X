import { useState } from 'react'
import AppShell from '../layout/AppShell'
import { useGuardianStore } from '../../stores/guardianStore'

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

const relationshipLabels: Record<string, string> = {
  spouse: '배우자',
  child: '자녀',
  friend: '지인',
  organization: '기관',
}

export default function HeirManagerView() {
  const { heirs, addHeir, removeHeir } = useGuardianStore()
  const [showForm, setShowForm] = useState(false)
  const [name, setName] = useState('')
  const [email, setEmail] = useState('')
  const [relationship, setRelationship] = useState<'spouse' | 'child' | 'friend' | 'organization'>('spouse')

  const handleAdd = () => {
    if (name && email) {
      addHeir({
        id: `h-${Date.now()}`,
        name,
        email,
        relationship,
        notificationStatus: 0,
      })
      setName('')
      setEmail('')
      setShowForm(false)
    }
  }

  return (
    <AppShell>
      <div style={{ maxWidth: 640, margin: '0 auto' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
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
            <h1 style={{ fontSize: 20, fontWeight: 600, color: C.text1, margin: 0 }}>상속인 관리</h1>
          </div>
          <span style={{ fontSize: 13, color: C.text2 }}>{heirs.length}명</span>
        </div>

        {showForm ? (
          <div
            style={{
              background: C.surface,
              borderRadius: 14,
              padding: 20,
              border: `1px solid ${C.accent}44`,
              marginBottom: 16,
            }}
          >
            <input
              placeholder="이름"
              value={name}
              onChange={(e) => setName(e.target.value)}
              style={{
                width: '100%',
                padding: '10px 14px',
                borderRadius: 10,
                border: `1px solid ${C.text2}44`,
                background: C.surface2,
                color: C.text1,
                fontSize: 14,
                marginBottom: 10,
                outline: 'none',
                boxSizing: 'border-box',
              }}
            />
            <input
              placeholder="이메일"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              style={{
                width: '100%',
                padding: '10px 14px',
                borderRadius: 10,
                border: `1px solid ${C.text2}44`,
                background: C.surface2,
                color: C.text1,
                fontSize: 14,
                marginBottom: 10,
                outline: 'none',
                boxSizing: 'border-box',
              }}
            />
            <select
              value={relationship}
              onChange={(e) => setRelationship(e.target.value as typeof relationship)}
              style={{
                width: '100%',
                padding: '10px 14px',
                borderRadius: 10,
                border: `1px solid ${C.text2}44`,
                background: C.surface2,
                color: C.text1,
                fontSize: 14,
                marginBottom: 16,
                outline: 'none',
                boxSizing: 'border-box',
              }}
            >
              <option value="spouse">배우자</option>
              <option value="child">자녀</option>
              <option value="friend">지인</option>
              <option value="organization">기관</option>
            </select>
            <div style={{ display: 'flex', gap: 10, justifyContent: 'flex-end' }}>
              <button
                onClick={() => setShowForm(false)}
                style={{
                  padding: '8px 20px',
                  borderRadius: 10,
                  border: `1px solid ${C.text2}44`,
                  background: 'none',
                  color: C.text2,
                  cursor: 'pointer',
                  fontSize: 13,
                }}
              >
                취소
              </button>
              <button
                onClick={handleAdd}
                style={{
                  padding: '8px 20px',
                  borderRadius: 10,
                  border: 'none',
                  background: C.accent,
                  color: '#000',
                  cursor: 'pointer',
                  fontSize: 13,
                  fontWeight: 600,
                }}
              >
                추가
              </button>
            </div>
          </div>
        ) : null}

        <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
          {heirs.map((heir) => (
            <div
              key={heir.id}
              style={{
                background: C.surface,
                borderRadius: 12,
                padding: 16,
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
                border: '1px solid rgba(255,255,255,0.05)',
              }}
            >
              <div>
                <p style={{ fontSize: 14, fontWeight: 600, color: C.text1, margin: '0 0 2px' }}>{heir.name}</p>
                <p style={{ fontSize: 12, color: C.text2, margin: 0 }}>{heir.email}</p>
                <span
                  style={{
                    fontSize: 11,
                    color: C.accent2,
                    marginTop: 4,
                    display: 'block',
                  }}
                >
                  {relationshipLabels[heir.relationship]}
                </span>
              </div>
              <button
                onClick={() => removeHeir(heir.id)}
                style={{
                  background: `${C.alert}15`,
                  color: C.alert,
                  border: 'none',
                  borderRadius: 8,
                  padding: '6px 14px',
                  cursor: 'pointer',
                  fontSize: 12,
                  fontWeight: 600,
                }}
              >
                삭제
              </button>
            </div>
          ))}
        </div>

        {!showForm && (
          <button
            onClick={() => setShowForm(true)}
            style={{
              position: 'fixed',
              bottom: 24,
              right: 24,
              width: 56,
              height: 56,
              borderRadius: '50%',
              background: C.accent,
              color: '#000',
              border: 'none',
              cursor: 'pointer',
              fontSize: 24,
              fontWeight: 700,
              boxShadow: `0 4px 20px ${C.accent}44`,
            }}
          >
            +
          </button>
        )}
      </div>
    </AppShell>
  )
}
