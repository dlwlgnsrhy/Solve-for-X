import { create } from 'zustand'

type ValueCategory = 'family' | 'career' | 'emotion' | 'challenge' | 'peace' | 'growth'

interface ValueKeyword {
  id: string
  word: string
  frequency: number
  firstOccurrence: number
  lastOccurrence: number
  category: ValueCategory
}

interface ValueEntry {
  id: string
  title: string
  content: string
  date: number
  sentiment: number
  keywords: ValueKeyword[]
  relatedEntryIds: string[]
}

interface ValueMappingState {
  keywords: ValueKeyword[]
  entries: ValueEntry[]
  selectedEntryId: string | null
  addKeyword: (kw: Omit<ValueKeyword, 'id'>) => void
  addEntry: (entry: Omit<ValueEntry, 'id'>) => void
  selectEntry: (id: string) => void
  deleteEntry: (id: string) => void
  getTopKeywords: (count: number) => ValueKeyword[]
}

const sampleKeywords: ValueKeyword[] = [
  { id: 'kw-001', word: '사랑', frequency: 47, firstOccurrence: Date.now() - 2592000000, lastOccurrence: Date.now(), category: 'family' },
  { id: 'kw-002', word: '자유', frequency: 32, firstOccurrence: Date.now() - 2592000000, lastOccurrence: Date.now() - 604800000, category: 'peace' },
  { id: 'kw-003', word: '도전', frequency: 28, firstOccurrence: Date.now() - 15552000000, lastOccurrence: Date.now() - 172800000, category: 'growth' },
  { id: 'kw-004', word: '가족', frequency: 55, firstOccurrence: Date.now() - 7776000000, lastOccurrence: Date.now(), category: 'family' },
  { id: 'kw-005', word: '목표', frequency: 21, firstOccurrence: Date.now() - 5184000000, lastOccurrence: Date.now() - 86400000, category: 'career' },
  { id: 'kw-006', word: '감사', frequency: 38, firstOccurrence: Date.now() - 3456000000, lastOccurrence: Date.now() - 43200000, category: 'emotion' },
  { id: 'kw-007', word: '스트레스', frequency: 19, firstOccurrence: Date.now() - 1209600000, lastOccurrence: Date.now() - 43200000, category: 'challenge' },
  { id: 'kw-008', word: '성장', frequency: 34, firstOccurrence: Date.now() - 4320000000, lastOccurrence: Date.now() - 172800000, category: 'growth' },
]

const sampleEntries: ValueEntry[] = [
  {
    id: 'entry-001',
    title: '어제의 대화에서 느낀 것',
    content: '가족과의 대화 속에서 진정한 사랑이란 함께 하는 시간임을 다시 한번 느꼈습니다.',
    date: Date.now() - 86400000,
    sentiment: 85,
    keywords: [sampleKeywords[0], sampleKeywords[3]],
    relatedEntryIds: ['entry-002'],
  },
  {
    id: 'entry-002',
    title: '새로운 목표 설정',
    content: '올해는 도전을 두려워하지 않고 새로운 것을 시도해야겠다고 다짐했습니다.',
    date: Date.now() - 172800000,
    sentiment: 60,
    keywords: [sampleKeywords[2], sampleKeywords[4]],
    relatedEntryIds: ['entry-001'],
  },
]

export const useValueMappingStore = create<ValueMappingState>()((set, get) => ({
  keywords: sampleKeywords,
  entries: sampleEntries,
  selectedEntryId: null,
  addKeyword: (kw) => set((state) => ({ keywords: [...state.keywords, { ...kw, id: `kw-${Date.now()}` }] })),
  addEntry: (entry) =>
    set((state) => ({ entries: [{ ...entry, id: `entry-${Date.now()}` }, ...state.entries] })),
  selectEntry: (id) => set({ selectedEntryId: id }),
  deleteEntry: (id) => set((state) => ({ entries: state.entries.filter((e) => e.id !== id) })),
  getTopKeywords: (count) =>
    [...get().keywords].sort((a, b) => b.frequency - a.frequency).slice(0, count),
}))
