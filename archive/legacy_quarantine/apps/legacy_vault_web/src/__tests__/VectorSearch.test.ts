import { describe, it, expect } from 'vitest';
import { db } from '@/lib/db';

describe('Vector DB', () => {
  it('should initialize Dexie database', () => {
    expect(db.name).toBe('LegacyVaultDB');
    const stores = db.tables.map(t => t.name);
    expect(stores).toContain('voiceLogEntries');
    expect(stores).toContain('vaultRecords');
    expect(stores).toContain('recordingVectors');
  });

  it('should have all 8 vector tables defined', () => {
    const expected = [
      'recordingVectors',
      'chatVectors',
      'keywordVectors',
      'voiceLogEntries',
      'vaultRecords',
      'inheritanceContacts',
      'chatMessages',
      'valueKeywords',
    ];
    const actual = db.tables.map(t => t.name);
    expected.forEach(table => expect(actual).toContain(table));
  });
});
