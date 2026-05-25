import { create } from 'zustand'

type VaultStatus = 'active' | 'paused' | 'expired' | 'alert_sent'
type NotificationStatus = 0 | 1 | 2 | 3 | 4

interface VaultRecord {
  id: string
  name: string
  vaultType: 'passwords' | 'legal' | 'financial' | 'photos' | 'videos' | 'custom'
  status: VaultStatus
  deadlineDays: number
  lastPingDate: number
  encryptedSize: number
}

interface InheritanceContact {
  id: string
  name: string
  email: string
  relationship: 'spouse' | 'child' | 'friend' | 'organization'
  notificationStatus: NotificationStatus
}

interface GuardianState {
  vaults: VaultRecord[]
  heirs: InheritanceContact[]
  daysSinceLastPing: number
  isDeadManActive: boolean
  deadManDeadline: number
  addVault: (vault: VaultRecord) => void
  removeVault: (id: string) => void
  addHeir: (heir: InheritanceContact) => void
  removeHeir: (id: string) => void
  updateDeadManSettings: (days: number, active: boolean) => void
}

const sampleVaults: VaultRecord[] = [
  {
    id: 'v-001',
    name: '비밀번호 보관함',
    vaultType: 'passwords',
    status: 'active',
    deadlineDays: 30,
    lastPingDate: Date.now() - 86400000,
    encryptedSize: 2048,
  },
  {
    id: 'v-002',
    name: '법적 문서',
    vaultType: 'legal',
    status: 'active',
    deadlineDays: 60,
    lastPingDate: Date.now() - 3600000,
    encryptedSize: 15360,
  },
]

const sampleHeirs: InheritanceContact[] = [
  {
    id: 'h-001',
    name: '김영희',
    email: 'younghee@email.com',
    relationship: 'spouse',
    notificationStatus: 0,
  },
  {
    id: 'h-002',
    name: '김민수',
    email: 'minsu@email.com',
    relationship: 'child',
    notificationStatus: 0,
  },
]

export const useGuardianStore = create<GuardianState>()((set) => ({
  vaults: sampleVaults,
  heirs: sampleHeirs,
  daysSinceLastPing: 1,
  isDeadManActive: false,
  deadManDeadline: 30,
  addVault: (vault) => set((state) => ({ vaults: [vault, ...state.vaults] })),
  removeVault: (id) => set((state) => ({ vaults: state.vaults.filter((v) => v.id !== id) })),
  addHeir: (heir) => set((state) => ({ heirs: [...state.heirs, heir] })),
  removeHeir: (id) => set((state) => ({ heirs: state.heirs.filter((h) => h.id !== id) })),
  updateDeadManSettings: (days, active) =>
    set({ deadManDeadline: days, isDeadManActive: active }),
}))
