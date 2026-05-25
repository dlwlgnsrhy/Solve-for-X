import { create } from 'zustand'

interface Session {
  passcode: string
  locked: boolean
}

export const useAuthStore = create<Session>(() => ({
  passcode: '',
  locked: true,
}))
