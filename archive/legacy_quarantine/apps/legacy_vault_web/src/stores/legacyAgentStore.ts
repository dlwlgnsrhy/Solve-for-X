import { create } from 'zustand'

interface ChatMessage {
  id: string
  role: 'user' | 'assistant'
  content: string
  timestamp: number
}

interface LegacyAgentState {
  messages: ChatMessage[]
  personaName: string
  personaVoice: string
  personaStyle: string
  conversationCount: number
  sendMessage: (content: string) => void
  clearMessages: () => void
  updatePersona: (name: string, voice: string, style: string) => void
}

const defaultPersona = {
  name: '나의 기억',
  voice: 'warm-male',
  style: 'empathetic',
}

const initialMessages: ChatMessage[] = [
  {
    id: 'msg-001',
    role: 'assistant',
    content: '안녕하세요. 저는 당신의 기억과 이야기를 보존하는 도우미입니다. 무엇인가 나누고 싶은 이야기가 있으신가요?',
    timestamp: Date.now() - 3600000,
  },
]

export const useLegacyAgentStore = create<LegacyAgentState>()((set) => ({
  messages: initialMessages,
  personaName: defaultPersona.name,
  personaVoice: defaultPersona.voice,
  personaStyle: defaultPersona.style,
  conversationCount: 42,
  sendMessage: (content) =>
    set((state) => ({
      messages: [
        ...state.messages,
        {
          id: `msg-${Date.now()}`,
          role: 'user',
          content,
          timestamp: Date.now(),
        },
      ],
      conversationCount: state.conversationCount + 1,
    })),
  clearMessages: () =>
    set({
      messages: [
        {
          id: `msg-${Date.now()}`,
          role: 'assistant',
          content: '대화가 초기화되었습니다. 새로운 이야기를 시작해보세요.',
          timestamp: Date.now(),
        },
      ],
    }),
  updatePersona: (name, voice, style) => set({ personaName: name, personaVoice: voice, personaStyle: style }),
}))
