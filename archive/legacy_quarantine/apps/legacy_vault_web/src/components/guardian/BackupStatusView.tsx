import { useGuardianStore } from '../../stores/guardianStore'
import AppShell from '../layout/AppShell'

const C = {
  background: '#0A0A0F',
  surface: '#1A1A2E',
  surface2: '#2A2A3E',
  accent: '#00FF88',
  text1: '#E8E8ED',
  text2: '#8E8EA0',
} as const

const formatBytes = (bytes: number) => {
  if (bytes < 1024) return `${bytes} B`
  if (bytes < 1048576) return `${(bytes / 1024).toFixed(0)} KB`
  return `${(bytes / 1048576).toFixed(1)} MB`
}

export default function BackupStatusView() {
  const { vaults } = useGuardianStore()

  return (
    <AppShell>
      <div style={{ maxWidth: 640, margin: '0 auto' }}>
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
          <h1 style={{ fontSize: 20, fontWeight: 600, color: C.text1, margin: 0 }}>백업 상태</h1>
        </div>

        <div
          style={{
            background: C.surface,
            borderRadius: 16,
            padding: 24,
            border: '1px solid rgba(255,255,255,0.05)',
            marginBottom: 16,
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 16 }}>
            <span style={{ fontSize: 20 }}>🔒</span>
            <span style={{ fontSize: 14, fontWeight: 600, color: C.accent }}>모든 백업 암호화됨</span>
          </div>
          <p style={{ fontSize: 13, color: C.text2, margin: '0 0 16px' }}>
            AES-GCM 256비트 암호화 적용 | 마지막 백업: 1일 전
          </p>

          {vaults.map((vault) => (
            <div
              key={vault.id}
              style={{
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
                padding: '12px 0',
                borderBottom: `1px solid ${C.surface2}`,
              }}
            >
              <div>
                <p style={{ fontSize: 14, fontWeight: 500, color: C.text1, margin: '0 0 2px' }}>{vault.name}</p>
                <p style={{ fontSize: 12, color: C.text2, margin: 0 }}>
                  {formatBytes(vault.encryptedSize)} | {new Date(vault.lastPingDate).toLocaleDateString('ko-KR')}
                </p>
              </div>
              <span
                style={{
                  fontSize: 11,
                  color: C.accent,
                  background: `${C.accent}14`,
                  padding: '3px 10px',
                  borderRadius: 8,
                  fontWeight: 600,
                }}
              >
                암호화됨
              </span>
            </div>
          ))}
        </div>

        <button
          style={{
            width: '100%',
            padding: '14px',
            borderRadius: 12,
            background: C.surface2,
            color: C.text1,
            border: `1px solid ${C.text2}33`,
            cursor: 'pointer',
            fontSize: 14,
            fontWeight: 600,
          }}
        >
          📦 백업 내보내기 (ZIP)
        </button>
      </div>
    </AppShell>
  )
}
