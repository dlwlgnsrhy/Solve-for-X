import Dexie, { type Table } from 'dexie';

export interface VoiceLogEntry {
  id: string;
  title: string;
  recordingDate: number;
  transcript: string;
  aiSummary: string | null;
  aiEnrichment: string[];
  sentiment: number;
  durationMs: number;
  keywords: string[];
  embeddingId: string | null;
}

export interface VaultRecord {
  id: string;
  name: string;
  vaultType: string;
  encryptedData: string;
  salt: string;
  lastPingDate: number;
  deadlineDays: number;
  targetEmails: string[];
  status: string;
}

export interface InheritanceContact {
  id: string;
  name: string;
  email: string;
  relationship: string;
  notificationStatus: number;
}

export interface ChatMessage {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  timestamp: number;
  embeddingId: string | null;
}

export interface ValueKeyword {
  id: string;
  word: string;
  frequency: number;
  firstOccurrence: number;
  lastOccurrence: number;
  category: string;
}

export class LegacyVaultDB extends Dexie {
  voiceLogEntries!: Table<VoiceLogEntry, string>;
  vaultRecords!: Table<VaultRecord, string>;
  inheritanceContacts!: Table<InheritanceContact, string>;
  chatMessages!: Table<ChatMessage, string>;
  valueKeywords!: Table<ValueKeyword, string>;
  recordingVectors!: Table<{ id: string; embedding: Float32Array; embeddingId: string }, string>;
  chatVectors!: Table<{ id: string; embedding: Float32Array; messageId: string }, string>;
  keywordVectors!: Table<{ id: string; embedding: Float32Array; keywordId: string }, string>;

  constructor() {
    super('LegacyVaultDB');
    this.version(1).stores({
      voiceLogEntries: 'id,recordingDate',
      vaultRecords: 'id,status',
      inheritanceContacts: 'id',
      chatMessages: 'id,timestamp',
      valueKeywords: 'id',
      recordingVectors: 'id,embeddingId',
      chatVectors: 'id,messageId',
      keywordVectors: 'id,keywordId',
    });
  }
}

export const db = new LegacyVaultDB();
