import { create } from 'zustand'

interface VoiceLogEntry {
  id: string
  title: string
  recordingDate: number
  transcript?: string
  aiSummary?: string
  sentiment: number
  durationMs: number
  audioURL?: string
  keywords: string[]
}

interface SoulMiningState {
  logs: VoiceLogEntry[]
  isRecording: boolean
  currentLog: VoiceLogEntry | null
  addLog: (log: VoiceLogEntry) => void
  startRecording: () => void
  stopRecording: (log: Partial<VoiceLogEntry>) => void
  deleteLog: (id: string) => void
}

const initialState: VoiceLogEntry[] = [
  {
    id: 'log-001',
    title: '오늘의 깨달음',
    recordingDate: Date.now() - 86400000,
    sentiment: 72,
    durationMs: 120000,
    keywords: ['가족', '성장', '목표'],
  },
  {
    id: 'log-002',
    title: '직무 고민 정리',
    recordingDate: Date.now() - 172800000,
    sentiment: -15,
    durationMs: 245000,
    keywords: ['진로', '스트레스', '협상'],
  },
  {
    id: 'log-003',
    title: '여행 메모리',
    recordingDate: Date.now() - 259200000,
    sentiment: 95,
    durationMs: 180000,
    keywords: ['여행', '평화', '자연'],
  },
]

export const useSoulMiningStore = create<SoulMiningState>()((set) => ({
  logs: initialState,
  isRecording: false,
  currentLog: null,
  addLog: (log) => set((state) => ({ logs: [log, ...state.logs] })),
  startRecording: () => set({ isRecording: true, currentLog: null }),
  stopRecording: (log) =>
    set((state) => ({
      isRecording: false,
      currentLog: null,
      logs: [
        {
          id: `log-${Date.now()}`,
          title: log.title || '새 녹음',
          recordingDate: Date.now(),
          sentiment: log.sentiment || 0,
          durationMs: log.durationMs || 0,
          transcript: log.transcript || '',
          aiSummary: log.aiSummary,
          audioURL: log.audioURL,
          keywords: log.keywords || [],
        },
        ...state.logs,
      ],
    })),
  deleteLog: (id) => set((state) => ({ logs: state.logs.filter((l) => l.id !== id) })),
}))
